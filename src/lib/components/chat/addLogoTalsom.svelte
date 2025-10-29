<script>
	import { config } from '$lib/stores';
</script>

<!-- Ajouter logo Talsom -->
{#if $config?.ui?.chat_logo_url}
	<div class="fixed-image-container flex justify-center">
		<a href="https://www.talsom.com/services/intelligence-artificielle-analytique-de-donnees/" target="_blank">
			<img 
				src={$config.ui.chat_logo_url} 
				alt="Propulsé par Talsom AI" 
				width="100"
			/>
		</a>
	</div>
{/if}
