import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_tools/network_tools.dart';
import 'dart:async';

class HostScannerScreen extends StatefulWidget {
  const HostScannerScreen({super.key});

  @override
  State<HostScannerScreen> createState() => _HostScannerScreenState();
}

class _HostScannerScreenState extends State<HostScannerScreen> {
  final TextEditingController _subnetController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final List<ActiveHost> _discoveredHosts = [];
  final List<OpenPort> _openPorts = [];
  bool _isScanning = false;
  bool _isScanningPorts = false;
  String _scanStatus = '';
  StreamSubscription<ActiveHost>? _hostSubscription;
  StreamSubscription<ActiveHost>? _portSubscription;

  @override
  void initState() {
    super.initState();
    _subnetController.text = '192.168.1.0/24';
    _portController.text = '22,80,443,8080';
  }

  @override
  void dispose() {
    _hostSubscription?.cancel();
    _portSubscription?.cancel();
    _subnetController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _scanHosts() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _discoveredHosts.clear();
      _scanStatus = 'Scanning for active hosts...';
    });

    try {
      final subnet = _subnetController.text.trim();
      if (subnet.isEmpty) {
        throw Exception('Please enter a valid subnet');
      }

      final stream = HostScannerService.instance.getAllPingableDevices(
        subnet,
        firstHostId: 1,
        lastHostId: 254,
        progressCallback: (progress) {
          setState(() {
            _scanStatus = 'Scanning... ${(progress * 100).toInt()}%';
          });
        },
      );

      _hostSubscription = stream.listen(
        (host) {
          setState(() {
            _discoveredHosts.add(host);
            _scanStatus = 'Found ${_discoveredHosts.length} hosts';
          });
        },
        onDone: () {
          setState(() {
            _isScanning = false;
            _scanStatus = 'Scan completed. Found ${_discoveredHosts.length} hosts';
          });
        },
        onError: (error) {
          setState(() {
            _isScanning = false;
            _scanStatus = 'Error: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanStatus = 'Error: $e';
      });
    }
  }

  Future<void> _scanPorts(String hostAddress) async {
    if (_isScanningPorts) return;

    setState(() {
      _isScanningPorts = true;
      _openPorts.clear();
    });

    try {
      final portsText = _portController.text.trim();
      if (portsText.isEmpty) {
        throw Exception('Please enter ports to scan');
      }

      final ports = portsText
          .split(',')
          .map((p) => int.tryParse(p.trim()))
          .where((p) => p != null)
          .cast<int>()
          .toList();

      if (ports.isEmpty) {
        throw Exception('Please enter valid port numbers');
      }

      final stream = PortScannerService.instance.customDiscover(
        hostAddress,
        portList: ports,
        progressCallback: (progress) {
          setState(() {
            _scanStatus = 'Scanning ports... ${(progress * 100).toInt()}%';
          });
        },
      );

      _portSubscription = stream.listen(
        (openPort) {
          setState(() {
            _openPorts.addAll(openPort.openPorts);
          });
        },
        onDone: () {
          setState(() {
            _isScanningPorts = false;
            _scanStatus = 'Port scan completed. Found ${_openPorts.length} open ports';
          });
        },
        onError: (error) {
          setState(() {
            _isScanningPorts = false;
            _scanStatus = 'Port scan error: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isScanningPorts = false;
        _scanStatus = 'Error: $e';
      });
    }
  }

  void _stopScan() {
    _hostSubscription?.cancel();
    _portSubscription?.cancel();
    setState(() {
      _isScanning = false;
      _isScanningPorts = false;
      _scanStatus = 'Scan stopped';
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subnetController,
                      decoration: const InputDecoration(
                        labelText: 'Subnet (CIDR notation)',
                        hintText: '192.168.1.0/24',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Ports to scan (comma-separated)',
                        hintText: '22,80,443,8080',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isScanning ? null : _scanHosts,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(_isScanning ? 'Scanning...' : 'Scan Hosts'),
                        ),
                        const SizedBox(width: 16),
                        if (_isScanning || _isScanningPorts)
                          ElevatedButton.icon(
                            onPressed: _stopScan,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    if (_scanStatus.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _scanStatus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _scanStatus.startsWith('Error')
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discovered Hosts (${_discoveredHosts.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _discoveredHosts.isEmpty
                                  ? const Center(
                                      child: Text('No hosts discovered yet'),
                                    )
                                  : ListView.builder(
                                      itemCount: _discoveredHosts.length,
                                      itemBuilder: (context, index) {
                                        final host = _discoveredHosts[index];
                                        return ListTile(
                                          leading: const Icon(Icons.computer),
                                          title: Text(host.address),
                                          subtitle: Text(
                                            'Response time: ${host.responseTime?.inMilliseconds ?? 'N/A'} ms',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.search),
                                                onPressed: () => _scanPorts(host.address),
                                                tooltip: 'Scan ports',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy),
                                                onPressed: () => _copyToClipboard(host.address),
                                                tooltip: 'Copy IP',
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Ports (${_openPorts.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _openPorts.isEmpty
                                  ? const Center(
                                      child: Text('No open ports found yet'),
                                    )
                                  : ListView.builder(
                                      itemCount: _openPorts.length,
                                      itemBuilder: (context, index) {
                                        final port = _openPorts[index];
                                        return ListTile(
                                          leading: const Icon(Icons.lock_open),
                                          title: Text('Port ${port.port}'),
                                          subtitle: Text(
                                            'port.ip- ${_getPortDescription(port.port)}',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.copy),
                                            onPressed: () => _copyToClipboard(
                                              'port.address:${port.port}',
                                            ),
                                            tooltip: 'Copy address:port',
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPortDescription(int port) {
    const portDescriptions = {
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      110: 'POP3',
      143: 'IMAP',
      443: 'HTTPS',
      993: 'IMAPS',
      995: 'POP3S',
      3389: 'RDP',
      5432: 'PostgreSQL',
      3306: 'MySQL',
      1433: 'SQL Server',
      8080: 'HTTP Alt',
      8443: 'HTTPS Alt',
    };
    return portDescriptions[port] ?? 'Unknown';
  }
}