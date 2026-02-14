import 'package:cipher_core/bindings/client.dart';
import 'package:cipher_core/generated_bindings.dart/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:async';
import 'dart:convert';

void main() async {
  await RustLib.init();
  runApp(const HashBenchmarkApp());
}

class HashBenchmarkApp extends StatelessWidget {
  const HashBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprehensive Hash Benchmark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D9FF),
          secondary: const Color(0xFFFF006E),
          tertiary: const Color(0xFF00F5FF),
          surface: const Color(0xFF0A0E27),
          surfaceContainer: const Color(0xFF1A1F3A),
          outline: const Color(0xFF2D3561),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E27),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const BenchmarkScreen(),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _sizeController = TextEditingController(text: '1');
  final TextEditingController _iterationsController =
  TextEditingController(text: '100');

  late TabController _tabController;
  final ValueNotifier<bool> _isRunning = ValueNotifier(false);
  final ValueNotifier<String> _currentTest = ValueNotifier('');
  final ValueNotifier<List<AlgorithmBenchmarkResult>> _results =
  ValueNotifier([]);

  // Algorithm selection states
  final ValueNotifier<Set<String>> _selectedOneShot = ValueNotifier({
    'SHA-1',
    'SHA-256',
    'SHA-512',
    'MD5',
  });
  final ValueNotifier<Set<String>> _selectedStreaming = ValueNotifier({
    'SHA-256',
    'SHA-512',
  });

  final List<String> _availableOneShotAlgos = [
    'SHA-1',
    'SHA-224',
    'SHA-256',
    'SHA-384',
    'SHA-512',
    'SHA-512/224',
    'SHA-512/256',
    'MD5',
  ];

  final List<String> _availableStreamingAlgos = [
    'SHA-256',
    'SHA-512',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _iterationsController.dispose();
    _tabController.dispose();
    _isRunning.dispose();
    _currentTest.dispose();
    _results.dispose();
    _selectedOneShot.dispose();
    _selectedStreaming.dispose();
    super.dispose();
  }

  Future<void> _runComprehensiveBenchmark() async {
    if (_isRunning.value) return;

    _isRunning.value = true;
    _results.value = [];
    _currentTest.value = '';

    try {
      final sizeMB = int.tryParse(_sizeController.text) ?? 1;
      final iterations = int.tryParse(_iterationsController.text) ?? 100;
      final warmupIterations = (iterations * 0.1).round().clamp(5, 20);

      // Pre-generate data
      final data = List<int>.generate(sizeMB * 1024 * 1024, (i) => i % 256);

      // Build test list based on selected algorithms
      final tests = <BenchmarkTest>[];

      // One-shot tests
      for (final algo in _selectedOneShot.value) {
        tests.addAll(_getOneShotTests(algo));
      }

      // Streaming tests
      for (final algo in _selectedStreaming.value) {
        tests.addAll(_getStreamingTests(algo));
      }

      final newResults = <AlgorithmBenchmarkResult>[];

      // Run all benchmarks
      for (final test in tests) {
        _currentTest.value = '${test.algorithm} (${test.implementation})';

        // Warmup
        for (int i = 0; i < warmupIterations; i++) {
          if (test.syncOp != null) {
            test.syncOp!(data);
          } else {
            await test.asyncOp!(data);
          }
        }

        // Benchmark
        final times = <double>[];
        for (int i = 0; i < iterations; i++) {
          final start = DateTime.now().microsecondsSinceEpoch;
          if (test.syncOp != null) {
            test.syncOp!(data);
          } else {
            await test.asyncOp!(data);
          }
          final elapsed = DateTime.now().microsecondsSinceEpoch - start;
          times.add(elapsed / 1000.0);
        }

        // Calculate statistics
        times.sort();
        final median = times[iterations ~/ 2];
        final min = times.first;
        final max = times.last;
        final mean = times.reduce((a, b) => a + b) / times.length;
        final variance = times
            .map((t) => (t - mean) * (t - mean))
            .reduce((a, b) => a + b) /
            times.length;
        final stdDev = variance > 0.0 ? variance : 0.0;

        newResults.add(AlgorithmBenchmarkResult(
          algorithm: test.algorithm,
          implementation: test.implementation,
          medianMs: median,
          minMs: min,
          maxMs: max,
          meanMs: mean,
          stdDevMs: stdDev,
          throughputMBs: (sizeMB * 1000) / median,
          iterations: iterations,
        ));

        // Update results without setState - just modify the list
        _results.value = List.from(newResults);

        // Allow UI to update
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Sort results by algorithm and implementation
      newResults.sort((a, b) {
        final algoCompare = a.algorithm.compareTo(b.algorithm);
        if (algoCompare != 0) return algoCompare;
        return a.implementation.compareTo(b.implementation);
      });

      _results.value = newResults;
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF006E),
          ),
        );
      }
      debugPrint('Benchmark error: $e\n$stackTrace');
    } finally {
      _isRunning.value = false;
      _currentTest.value = '';
    }
  }

  List<BenchmarkTest> _getOneShotTests(String algo) {
    switch (algo) {
      case 'SHA-1':
        return [
          BenchmarkTest(
            'SHA-1 (one-shot)',
            'crypto',
                (data) => crypto.sha1.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-1 (one-shot)',
            'rust',
                (data) => sha1.convert(data),
            null,
          ),
        ];
      case 'SHA-224':
        return [
          BenchmarkTest(
            'SHA-224 (one-shot)',
            'crypto',
                (data) => crypto.sha224.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-224 (one-shot)',
            'rust',
                (data) => sha224.convert(data),
            null,
          ),
        ];
      case 'SHA-256':
        return [
          BenchmarkTest(
            'SHA-256 (one-shot)',
            'crypto',
                (data) => crypto.sha256.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-256 (one-shot)',
            'rust',
                (data) => sha256.convert(data),
            null,
          ),
        ];
      case 'SHA-384':
        return [
          BenchmarkTest(
            'SHA-384 (one-shot)',
            'crypto',
                (data) => crypto.sha384.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-384 (one-shot)',
            'rust',
                (data) => sha384.convert(data),
            null,
          ),
        ];
      case 'SHA-512':
        return [
          BenchmarkTest(
            'SHA-512 (one-shot)',
            'crypto',
                (data) => crypto.sha512.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-512 (one-shot)',
            'rust',
                (data) => sha512.convert(data),
            null,
          ),
        ];
      case 'SHA-512/224':
        return [
          BenchmarkTest(
            'SHA-512/224 (one-shot)',
            'crypto',
                (data) => crypto.sha512224.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-512/224 (one-shot)',
            'rust',
                (data) => sha512_224.convert(data),
            null,
          ),
        ];
      case 'SHA-512/256':
        return [
          BenchmarkTest(
            'SHA-512/256 (one-shot)',
            'crypto',
                (data) => crypto.sha512256.convert(data),
            null,
          ),
          BenchmarkTest(
            'SHA-512/256 (one-shot)',
            'rust',
                (data) => sha512_256.convert(data),
            null,
          ),
        ];
      case 'MD5':
        return [
          BenchmarkTest(
            'MD5 (one-shot)',
            'crypto',
                (data) => crypto.md5.convert(data),
            null,
          ),
          BenchmarkTest(
            'MD5 (one-shot)',
            'rust',
                (data) => md5.convert(data),
            null,
          ),
        ];
      default:
        return [];
    }
  }

  List<BenchmarkTest> _getStreamingTests(String algo) {
    switch (algo) {
      case 'SHA-256':
        return [
          BenchmarkTest(
            'SHA-256 (streaming)',
            'crypto',
                (data) {
              final sink = crypto.sha256.startChunkedConversion(
                ChunkedConversionSink<crypto.Digest>.withCallback(
                        (digest) {}),
              );
              sink.add(data);
              sink.close();
            },
            null,
          ),
          BenchmarkTest(
            'SHA-256 (streaming)',
            'rust',
                (data) {
              final hasher = sha256.newHasher();
              hasher.add(data);
              hasher.close();
            },
            null,
          ),
        ];
      case 'SHA-512':
        return [
          BenchmarkTest(
            'SHA-512 (streaming)',
            'crypto',
                (data) {
              final sink = crypto.sha512.startChunkedConversion(
                ChunkedConversionSink<crypto.Digest>.withCallback(
                        (digest) {}),
              );
              sink.add(data);
              sink.close();
            },
            null,
          ),
          BenchmarkTest(
            'SHA-512 (streaming)',
            'rust',
                (data) {
              final hasher = sha512.newHasher();
              hasher.add(data);
              hasher.close();
            },
            null,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Fixed header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00D9FF).withOpacity(0.1),
                  const Color(0xFFFF006E).withOpacity(0.1),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hash Benchmark',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00D9FF),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rust vs Dart Crypto Performance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF00D9FF),
                    labelColor: const Color(0xFF00D9FF),
                    unselectedLabelColor: Colors.white.withOpacity(0.6),
                    tabs: const [
                      Tab(text: 'One-Shot'),
                      Tab(text: 'Streaming'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlgorithmSelector(
                    _availableOneShotAlgos, _selectedOneShot),
                _buildAlgorithmSelector(
                    _availableStreamingAlgos, _selectedStreaming),
              ],
            ),
          ),
          // Fixed bottom section with config and button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E27),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildConfigCard(),
                    const SizedBox(height: 16),
                    _buildBenchmarkButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmSelector(
      List<String> algorithms, ValueNotifier<Set<String>> selected) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selected,
      builder: (context, selectedSet, _) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Algorithms',
                        style:
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (selectedSet.length == algorithms.length) {
                            selected.value = {};
                          } else {
                            selected.value = algorithms.toSet();
                          }
                        },
                        child: Text(
                          selectedSet.length == algorithms.length
                              ? 'Deselect All'
                              : 'Select All',
                          style: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...algorithms.map((algo) {
                    final isSelected = selectedSet.contains(algo);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        color: isSelected
                            ? const Color(0xFF00D9FF).withOpacity(0.1)
                            : const Color(0xFF1A1F3A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF00D9FF)
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            algo,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF00D9FF)
                                  : Colors.white,
                            ),
                          ),
                          value: isSelected,
                          activeColor: const Color(0xFF00D9FF),
                          onChanged: (bool? value) {
                            final newSet = Set<String>.from(selectedSet);
                            if (value == true) {
                              newSet.add(algo);
                            } else {
                              newSet.remove(algo);
                            }
                            selected.value = newSet;
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<List<AlgorithmBenchmarkResult>>(
                    valueListenable: _results,
                    builder: (context, results, _) {
                      if (results.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.flash_off_rounded,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Run benchmark to see results',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(results),
                          const SizedBox(height: 24),
                          Text(
                            'Detailed Results',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._buildResultCards(results),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigCard() {
    return Card(
      color: const Color(0xFF1A1F3A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Size (MB)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isRunning,
                    builder: (context, isRunning, _) {
                      return TextField(
                        controller: _sizeController,
                        enabled: !isRunning,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iterations',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isRunning,
                    builder: (context, isRunning, _) {
                      return TextField(
                        controller: _iterationsController,
                        enabled: !isRunning,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isRunning,
      builder: (context, isRunning, _) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.tonal(
            onPressed: isRunning ? null : _runComprehensiveBenchmark,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              disabledBackgroundColor:
              const Color(0xFF00D9FF).withOpacity(0.5),
              foregroundColor: const Color(0xFF0A0E27),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isRunning
                ? ValueListenableBuilder<String>(
              valueListenable: _currentTest,
              builder: (context, currentTest, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF0A0E27).withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        currentTest.isEmpty ? 'Running...' : currentTest,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A0E27).withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            )
                : const Text(
              'Run Benchmark',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(List<AlgorithmBenchmarkResult> results) {
    // Group results by algorithm
    final grouped = <String, List<AlgorithmBenchmarkResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.algorithm, () => []).add(result);
    }

    // Filter out groups that don't have both implementations
    final validGroups = grouped.entries
        .where((entry) => entry.value.length == 2)
        .toList();

    if (validGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF1A1F3A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...validGroups.map((entry) {
              final algo = entry.key;
              final resultsList = entry.value;
              final cryptoResult =
              resultsList.firstWhere((r) => r.implementation == 'crypto');
              final rustResult =
              resultsList.firstWhere((r) => r.implementation == 'rust');

              // Calculate speedup: how much faster is Rust compared to Dart crypto
              // If Rust takes less time (faster), speedup > 1
              // If crypto takes less time (faster), speedup < 1
              final speedup = cryptoResult.medianMs / rustResult.medianMs;
              final rustIsFaster = speedup > 1;

              // Show the speedup value with correct label
              final String speedupText;
              if (rustIsFaster) {
                // Rust is faster - show how many times faster
                speedupText = 'Rust ${speedup.toStringAsFixed(1)}x faster';
              } else {
                // Crypto is faster - show how many times faster
                speedupText = 'Rust ${(1 / speedup).toStringAsFixed(1)}x slower';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: rustIsFaster
                          ? const Color(0xFF00F5FF).withOpacity(0.3)
                          : const Color(0xFFFF006E).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          algo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          speedupText,
                          style: TextStyle(
                            color: rustIsFaster
                                ? const Color(0xFF00F5FF)
                                : const Color(0xFFFF006E),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        rustIsFaster ? Icons.trending_up : Icons.trending_down,
                        color: rustIsFaster
                            ? const Color(0xFF00F5FF)
                            : const Color(0xFFFF006E),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultCards(List<AlgorithmBenchmarkResult> results) {
    return results.map((result) {
      final isRust = result.implementation == 'rust';
      final accentColor = isRust ? const Color(0xFF00F5FF) : Colors.white;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          color: const Color(0xFF1A1F3A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: accentColor.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.algorithm,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.implementation.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMetricRow(
                    'Median', '${result.medianMs.toStringAsFixed(3)}ms'),
                _buildMetricRow(
                    'Mean', '${result.meanMs.toStringAsFixed(3)}ms'),
                _buildMetricRow('Min', '${result.minMs.toStringAsFixed(3)}ms'),
                _buildMetricRow('Max', '${result.maxMs.toStringAsFixed(3)}ms'),
                _buildMetricRow(
                    'Std Dev', '${result.stdDevMs.toStringAsFixed(3)}ms'),
                const Divider(height: 16),
                _buildMetricRow(
                  'Throughput',
                  '${result.throughputMBs.toStringAsFixed(2)} MB/s',
                  highlight: true,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMetricRow(String label, String value,
      {bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? (color ?? Colors.white) : Colors.white,
              fontSize: highlight ? 13 : 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkTest {
  final String algorithm;
  final String implementation;
  final Function(List<int>)? syncOp;
  final Future<dynamic> Function(List<int>)? asyncOp;

  BenchmarkTest(this.algorithm, this.implementation, this.syncOp, this.asyncOp);
}

class AlgorithmBenchmarkResult {
  final String algorithm;
  final String implementation;
  final double medianMs;
  final double minMs;
  final double maxMs;
  final double meanMs;
  final double stdDevMs;
  final double throughputMBs;
  final int iterations;

  AlgorithmBenchmarkResult({
    required this.algorithm,
    required this.implementation,
    required this.medianMs,
    required this.minMs,
    required this.maxMs,
    required this.meanMs,
    required this.stdDevMs,
    required this.throughputMBs,
    required this.iterations,
  });
}