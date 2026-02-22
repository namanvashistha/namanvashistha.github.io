export async function GET() {
	return new Response('export const search = () => { return { results: [] } }; export const init = () => {};', {
		headers: {
			'content-type': 'application/javascript',
		},
	});
}
