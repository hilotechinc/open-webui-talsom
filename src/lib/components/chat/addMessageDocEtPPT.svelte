<script context="module" lang="ts">
	import { toast } from 'svelte-sonner';

	/**
	 * Gère les erreurs d'upload de fichiers avec un meilleur parsing des messages d'erreur.
	 * Extrait correctement les messages détaillés des HTTPException du backend (notamment pour .doc et .ppt).
	 *
	 * @param e - L'erreur capturée (peut être string, object, ou autre)
	 */
	export function handleUploadError(e: any): void {
		console.log('Upload error object:', e);
		let errorMessage = 'Error uploading file';

		if (typeof e === 'string') {
			errorMessage = e;
		} else if (e && typeof e === 'object') {
			// Priorité au champ 'detail' pour les HTTPException du backend
			if (e.detail) {
				errorMessage = e.detail;
			} else if (e.message) {
				errorMessage = e.message;
			} else {
				errorMessage = JSON.stringify(e);
			}
		}

		console.log('Error message to display:', errorMessage);
		toast.error(errorMessage);
	}
</script>
