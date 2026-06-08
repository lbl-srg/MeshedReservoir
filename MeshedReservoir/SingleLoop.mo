within MeshedReservoir;
model SingleLoop
  Buildings.Fluid.FixedResistances.PressureDrop res
    annotation (Placement(transformation(extent={{60,-30},{80,-10}})));
  BaseClasses.ConditionalPump pum
    annotation (Placement(transformation(extent={{-40,-30},{-20,-10}})));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end SingleLoop;
