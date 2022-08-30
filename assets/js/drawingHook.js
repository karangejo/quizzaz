export default {
	mounted() {
		const canvas = document.getElementById('drawing-board');
		const toolbar = document.getElementById('toolbar');
		const ctx = canvas.getContext('2d');

		let canvasOffsetX = canvas.offsetLeft;
		let canvasOffsetY = canvas.offsetTop;
		let isPainting = false;
		let lineWidth = 5;
		let startX;
		let startY;

		document.getElementById('answer-drawing').addEventListener('click', e => {
			let canvasData = canvas.toDataURL();
			this.pushEvent("submit_picture", { 'data': canvasData })
		});

		const loadDrawing = () => {
			canvas.width = (window.innerWidth * 0.65)
			canvas.height = (window.innerHeight * 0.65)
			toolbar.style.height = `${Math.floor(window.innerHeight * 0.65)}px`

			canvasOffsetX = canvas.offsetLeft;
			canvasOffsetY = canvas.offsetTop;

			toolbar.addEventListener('click', e => {
				if (e.target.id === 'clear') {
					ctx.clearRect(0, 0, canvas.width, canvas.height);
				}
			});

			toolbar.addEventListener('change', e => {
				if (e.target.id === 'stroke') {
					ctx.strokeStyle = e.target.value;
				}

				if (e.target.id === 'lineWidth') {
					lineWidth = e.target.value;
				}

			});

			const draw = (e) => {
				if (!isPainting) {
					return;
				}

				ctx.lineWidth = lineWidth;
				ctx.lineCap = 'round';

				ctx.lineTo(e.clientX - canvasOffsetX, e.clientY - canvasOffsetY);
				ctx.stroke();
			}

			canvas.addEventListener('mousedown', (e) => {
				isPainting = true;
				startX = e.clientX;
				startY = e.clientY;
			});

			canvas.addEventListener('mouseup', e => {
				isPainting = false;
				ctx.stroke();
				ctx.beginPath();
			});

			canvas.addEventListener('mousemove', draw);


		}

		window.onresize = function () {
			loadDrawing()
		}

		loadDrawing();
	}
}