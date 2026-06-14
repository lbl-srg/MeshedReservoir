within MeshedReservoir.BaseClasses;
block PumpController "Controller for pump between two loops"
  parameter Modelica.Units.SI.TemperatureDifference dTHys=2
    "Control hysteresis";
  parameter Modelica.Units.SI.TemperatureDifference dTLoo_nominal=4
    "Loop design temperature difference";
  parameter Modelica.Units.SI.Temperature TLooMax_nominal(
    displayUnit="degC")
    "Maximum allowed loop temperature";
  parameter Modelica.Units.SI.Temperature TLooMin_nominal(
    displayUnit="degC")
    "Minimum allowed loop temperature";

  Buildings.Controls.OBC.CDL.Interfaces.RealInput TLoo1(
    final unit="K",
    final displayUnit="degC")
    "Temperature of loop 1"
    annotation (Placement(transformation(extent={{-140,40},{-100,80}}),
        iconTransformation(extent={{-140,40},{-100,80}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput TLoo2(
    final unit="K",
    final displayUnit="degC")
    "Temperature of loop 2"
    annotation (Placement(transformation(extent={{-140,-80},{-100,-40}}),
        iconTransformation(extent={{-140,-80},{-100,-40}})));

  Buildings.Controls.OBC.CDL.Interfaces.RealOutput yPum(
    final unit="1")
    "Pump control signal"
    annotation (Placement(transformation(extent={{100,-10},{120,10}}),
        iconTransformation(extent={{100,-10},{120,10}})));

  annotation (
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
      graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid)}),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}})));
end PumpController;