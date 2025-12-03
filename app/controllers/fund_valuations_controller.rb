class FundValuationsController < ApplicationController
  before_action :set_fund_valuation, only: %i[ show edit update destroy ]

  # GET /fund_valuations or /fund_valuations.json
  def index
    @fund_valuations = FundValuation.all
  end

  # GET /fund_valuations/1 or /fund_valuations/1.json
  def show
  end

  # GET /fund_valuations/new
  def new
    @fund_valuation = FundValuation.new
  end

  # GET /fund_valuations/1/edit
  def edit
  end

  # POST /fund_valuations or /fund_valuations.json
  def create
    @fund_valuation = FundValuation.new(fund_valuation_params)

    respond_to do |format|
      if @fund_valuation.save
        format.html { redirect_to @fund_valuation, notice: "Fund valuation was successfully created." }
        format.json { render :show, status: :created, location: @fund_valuation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fund_valuation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fund_valuations/1 or /fund_valuations/1.json
  def update
    respond_to do |format|
      if @fund_valuation.update(fund_valuation_params)
        format.html { redirect_to @fund_valuation, notice: "Fund valuation was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @fund_valuation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fund_valuation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fund_valuations/1 or /fund_valuations/1.json
  def destroy
    @fund_valuation.destroy!

    respond_to do |format|
      format.html { redirect_to fund_valuations_path, notice: "Fund valuation was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fund_valuation
      @fund_valuation = FundValuation.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def fund_valuation_params
      params.fetch(:fund_valuation, {})
    end
end
