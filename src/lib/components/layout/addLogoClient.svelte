<script>
	import { config } from '$lib/stores';
</script>

<!-- Ajouter logo Client -->
{#if $config?.ui?.client_logo_url}
	<div class="flex justify-center my-4">
		<img
			src={$config.ui.client_logo_url}
			alt="Logo Client"
			width="200"
		/>
	</div>
{/if}
