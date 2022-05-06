import Sortable from 'sortablejs';

export default {
	mounted() {

		document.querySelectorAll('.dropzone-letters').forEach((dropzone) => {
			Sortable.create(dropzone, {
				onEnd: (evt) => {
					let unscrambled = [].slice.call(evt.to.children).map((child) => {
						return child.innerText
					}).join('')
					this.pushEvent('unscrambled_word', { unscrambled: unscrambled })
				}
			});
		});

		document.querySelectorAll('.dropzone-words').forEach((dropzone) => {
			Sortable.create(dropzone, {
				onEnd: (evt) => {
					let unscrambled = [].slice.call(evt.to.children).map((child) => {
						return child.innerText
					})
					this.pushEvent('unscrambled_words', { unscrambled: unscrambled })
				}
			});
		});
	}
};