import Chart from 'chart.js/auto';

Chart.defaults.font.size = 22;
Chart.defaults.font.weight = "bold"

const randomColorGenerator = () => {
	return '#' + (Math.random().toString(16) + '0000000').slice(2, 8);
};

const generateColors = (length) => {
	let colors = []
	for (i = 0; i < length; i++) {
		colors.push(randomColorGenerator())
	}
	return colors
}

export default {
	mounted() {
		this.handleEvent("survey", ({ results }) => {
			const { labels, data } = results
			length = labels.length
			colors = generateColors(length)
			const ctx = document.getElementById('survey-chart');
			new Chart(ctx, {
				type: 'bar',
				data: {
					labels: labels,
					datasets: [{
						label: "# of votes",
						data: data,
						backgroundColor: colors
					}]
				},
				options: {
					scales: {
						y: {
							beginAtZero: true,
							ticks: {
								precision: 0
							}
						}
					}
				}
			});

		})
	}
}