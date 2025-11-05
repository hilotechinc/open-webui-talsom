<script>
	import { config } from '$lib/stores';
</script>

<!-- Ajouter logo Talsom -->
{#if $config?.ui?.chat_logo_url}
	<div class="fixed-image-container flex justify-center">
		{#if $config.ui.chat_logo_href_url}
			<a href={$config.ui.chat_logo_href_url} target="_blank">
				<img src={$config.ui.chat_logo_url} alt="Logo" width="100" />
			</a>
		{:else}
			<img src={$config.ui.chat_logo_url} alt="Logo" width="100" />
		{/if}
	</div>
{/if}
		