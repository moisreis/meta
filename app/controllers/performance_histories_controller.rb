class PerformanceHistoriesController < ApplicationController
  before_action :set_performance_history, only: %i[ show edit update destroy ]

  # GET /performance_histories or /performance_histories.json
  def index
    @performance_histories = PerformanceHistory.all
  end

  # GET /performance_histories/1 or /performance_histories/1.json
  def show
  end

  # GET /performance_histories/new
  def new
    @performance_history = PerformanceHistory.new
  end

  # GET /performance_histories/1/edit
  def edit
  end

  # POST /performance_histories or /performance_histories.json
  def create
    @performance_history = PerformanceHistory.new(performance_history_params)

    respond_to do |format|
      if @performance_history.save
        format.html { redirect_to @performance_history, notice: "Performance history was successfully created." }
        format.json { render :show, status: :created, location: @performance_history }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @performance_history.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /performance_histories/1 or /performance_histories/1.json
  def update
    respond_to do |format|
      if @performance_history.update(performance_history_params)
        format.html { redirect_to @performance_history, notice: "Performance history was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @performance_history }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @performance_history.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /performance_histories/1 or /performance_histories/1.json
  def destroy
    @performance_history.destroy!

    respond_to do |format|
      format.html { redirect_to performance_histories_path, notice: "Performance history was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_performance_history
      @performance_history = PerformanceHistory.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def performance_history_params
      params.fetch(:performance_history, {})
    end
end
