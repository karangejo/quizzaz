import Sortable from 'sortablejs';

export default {
	mounted() {

		document.querySelectorAll('.dropzone-letters').forEach((dropzone) => {
			Sortable.create(dropzone, {
				onEnd: (evt) => {
					console.log([].slice.call(evt.to.children))
					let unscrambled = [].slice.call(evt.to.children).map((child) => {
						console.log(child)
						return child.innerText
					}).join('')
					console.log(unscrambled)
					this.pushEvent('unscrambled_word', { unscrambled: unscrambled })
				}
			});
		});

		document.querySelectorAll('.dropzone-words').forEach((dropzone) => {
			Sortable.create(dropzone, {
				onEnd: (evt) => {
					console.log([].slice.call(evt.to.children))
					let unscrambled = [].slice.call(evt.to.children).map((child) => {
						console.log(child)
						return child.innerText
					})
					console.log(unscrambled)
					this.pushEvent('unscrambled_words', { unscrambled: unscrambled })
				}
			});
		});
	}
};