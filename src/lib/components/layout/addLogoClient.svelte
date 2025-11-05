<script>
	import { config } from '$lib/stores';
</script>

<!-- Ajouter logo Client -->
{#if $config?.ui?.client_logo_url}
	<div class="flex justify-center my-4">
		{#if $config.ui.client_logo_href_url}
      		<a href={$config.ui.client_logo_href_url} target="_blank">
         		 <img src={$config.ui.client_logo_url} alt="Logo Client" width="200" />
      		</a>
  		{:else}
      		<img src={$config.ui.client_logo_url} alt="Logo Client" width="200" />
 		{/if}
	</div>
{/if}
