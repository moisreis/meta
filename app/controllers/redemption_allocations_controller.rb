class RedemptionAllocationsController < ApplicationController
  before_action :set_redemption_allocation, only: %i[ show edit update destroy ]

  # GET /redemption_allocations or /redemption_allocations.json
  def index
    @redemption_allocations = RedemptionAllocation.all
  end

  # GET /redemption_allocations/1 or /redemption_allocations/1.json
  def show
  end

  # GET /redemption_allocations/new
  def new
    @redemption_allocation = RedemptionAllocation.new
  end

  # GET /redemption_allocations/1/edit
  def edit
  end

  # POST /redemption_allocations or /redemption_allocations.json
  def create
    @redemption_allocation = RedemptionAllocation.new(redemption_allocation_params)

    respond_to do |format|
      if @redemption_allocation.save
        format.html { redirect_to @redemption_allocation, notice: "Redemption allocation was successfully created." }
        format.json { render :show, status: :created, location: @redemption_allocation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @redemption_allocation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /redemption_allocations/1 or /redemption_allocations/1.json
  def update
    respond_to do |format|
      if @redemption_allocation.update(redemption_allocation_params)
        format.html { redirect_to @redemption_allocation, notice: "Redemption allocation was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @redemption_allocation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @redemption_allocation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /redemption_allocations/1 or /redemption_allocations/1.json
  def destroy
    @redemption_allocation.destroy!

    respond_to do |format|
      format.html { redirect_to redemption_allocations_path, notice: "Redemption allocation was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_redemption_allocation
      @redemption_allocation = RedemptionAllocation.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def redemption_allocation_params
      params.fetch(:redemption_allocation, {})
    end
end
