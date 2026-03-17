import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran de capture KYC — photos CNI/permis + activation livreur.
class KycCaptureScreen extends ConsumerStatefulWidget {
  const KycCaptureScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<KycCaptureScreen> createState() => _KycCaptureScreenState();
}

class _KycCaptureScreenState extends ConsumerState<KycCaptureScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  bool _isActivating = false;

  Future<void> _captureAndUpload(KycDocumentType docType) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      await ref.read(kycNotifierProvider.notifier).uploadDocument(
            userId: widget.userId,
            documentType: docType,
            fileBytes: bytes,
            fileName: image.name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${docType.label} uploade'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _activateDriver() async {
    setState(() => _isActivating = true);
    try {
      await ref
          .read(kycNotifierProvider.notifier)
          .activateDriver(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livreur active avec succes !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(kycSummaryProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Capture KYC')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (data) {
          final hasDocuments = data.documents.isNotEmpty;
          final hasCni =
              data.documents.any((d) => d.documentType == KycDocumentType.cni);
          final hasPermis =
              data.documents.any((d) => d.documentType == KycDocumentType.permis);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Infos livreur
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.user.name ?? 'Sans nom',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('Tel: ${data.user.phone}'),
                        if (data.sponsor != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Parrain: ${data.sponsor!.name ?? data.sponsor!.phone}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Documents
                Text(
                  "Documents d'identite",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _DocumentSlot(
                  label: "CNI (Carte Nationale d'Identite)",
                  isUploaded: hasCni,
                  isLoading: _isUploading,
                  onCapture: () => _captureAndUpload(KycDocumentType.cni),
                ),
                const SizedBox(height: 8),
                _DocumentSlot(
                  label: 'Permis de conduire',
                  isUploaded: hasPermis,
                  isLoading: _isUploading,
                  onCapture: () =>
                      _captureAndUpload(KycDocumentType.permis),
                ),
                const SizedBox(height: 24),

                // Bouton activation
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: hasDocuments && !_isActivating
                        ? _activateDriver
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: _isActivating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Activer le livreur'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.label,
    required this.isUploaded,
    required this.isLoading,
    required this.onCapture,
  });

  final String label;
  final bool isUploaded;
  final bool isLoading;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.check_circle : Icons.photo_camera,
          color: isUploaded ? Colors.green : null,
        ),
        title: Text(label),
        subtitle: Text(isUploaded ? 'Uploade' : 'Non capture'),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton(
                onPressed: isLoading ? null : onCapture,
                child: Text(isUploaded ? 'Refaire' : 'Capturer'),
              ),
      ),
    );
  }
}
