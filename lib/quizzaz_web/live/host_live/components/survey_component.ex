defmodule QuizzazWeb.HostLive.SurveyComponent do
  use QuizzazWeb, :live_component

  alias Quizzaz.Games.Questions.Survey

  def update(%{players: players, question: question}, socket) do
    survey_results = Survey.get_survey_results(players, question)
    {:ok, push_event(socket, "survey", %{"results" => survey_results})}
  end
end
