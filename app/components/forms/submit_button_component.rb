class Forms::SubmitButtonComponent < ApplicationComponent
  def initialize(builder:, method:, label: nil, icon: nil)
    @builder = builder
    @method  = method
    @label   = label || (editing? ? "Atualizar" : "Criar")
    @icon    = icon  || (editing? ? "save"      : "plus")
  end

  private

  def editing?
    @method == :patch || @method == :put
  end
end