within MeshedReservoir.BaseClasses;
model LevelController "Controller for mass flow rate"
  extends Buildings.BaseClasses.BaseIcon;

  parameter Real hys=0.1 "Hysteresis for comparing input with threshold";

  Buildings.Controls.OBC.CDL.Interfaces.RealInput err(
    final unit="1") "Control error"
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}}),
        iconTransformation(extent={{-140,-20},{-100,20}})));

  Buildings.Controls.OBC.CDL.Interfaces.RealOutput y(
    final min=-1,
    final max=1,
    unit="1")
    "Set point for mass flow rate, either -1, 0, or 1" annotation (Placement(
        transformation(extent={{100,-20},{140,20}}), iconTransformation(extent={
            {100,-20},{140,20}})));

  Buildings.Controls.OBC.CDL.Reals.AddParameter shi(p=0.5)
    "Shift the error so that 0.5 means no error"
    annotation (Placement(transformation(extent={{-90,-10},{-70,10}})));

  Buildings.Controls.OBC.CDL.Reals.Hysteresis hysLoa(uLow=0.3 - hys/2, uHigh=0.3
         + hys/2) "Hysteresis to load the vessel with air or water"
    annotation (Placement(transformation(extent={{-30,10},{-10,30}})));
  Buildings.Controls.OBC.CDL.Reals.Hysteresis hysUnl(uLow=0.7 - hys/2, uHigh=0.7
         + hys/2) "Hysteresis to unload the vessel with air or water"
    annotation (Placement(transformation(extent={{-30,-30},{-10,-10}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal booToReaLoa
    "Type conversion"
    annotation (Placement(transformation(extent={{10,10},{30,30}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal booToReaUnl(realTrue=0,
      realFalse=-1.0) "Type conversion"
    annotation (Placement(transformation(extent={{10,-30},{30,-10}})));
  Buildings.Controls.OBC.CDL.Reals.Add ySet "Control signal"
    annotation (Placement(transformation(extent={{60,-10},{80,10}})));
equation
  connect(shi.u, err)
    annotation (Line(points={{-92,0},{-120,0}}, color={0,0,127}));
  connect(shi.y, hysLoa.u) annotation (Line(points={{-68,0},{-50,0},{-50,20},{-32,
          20}}, color={0,0,127}));
  connect(hysLoa.y, booToReaLoa.u)
    annotation (Line(points={{-8,20},{8,20}}, color={255,0,255}));
  connect(hysUnl.y, booToReaUnl.u)
    annotation (Line(points={{-8,-20},{8,-20}}, color={255,0,255}));
  connect(shi.y, hysUnl.u) annotation (Line(points={{-68,0},{-50,0},{-50,-20},{-32,
          -20}}, color={0,0,127}));
  connect(ySet.y, y)
    annotation (Line(points={{82,0},{120,0}}, color={0,0,127}));
  connect(booToReaLoa.y, ySet.u1)
    annotation (Line(points={{32,20},{46,20},{46,6},{58,6}}, color={0,0,127}));
  connect(booToReaUnl.y, ySet.u2) annotation (Line(points={{32,-20},{46,-20},{46,
          -6},{58,-6}}, color={0,0,127}));
  annotation (Icon(graphics={Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{226,60},{106,10}},
          textColor={0,0,0},
          textString=DynamicSelect("",String(y,
            leftJustified=false,
            significantDigits=3)))}));
end LevelController;
