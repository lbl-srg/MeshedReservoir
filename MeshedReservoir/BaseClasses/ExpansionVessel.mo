within MeshedReservoir.BaseClasses;
model ExpansionVessel "ExpansionVessel"
 extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations(
   final energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
   final massDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
   final mSenFac=1);
  parameter Modelica.Units.SI.Volume V_start(start=1)
    "Volume of liquid stored in the vessel at the start of the simulation";

  Modelica.Fluid.Interfaces.FluidPort_a port_a(
    redeclare package Medium = Medium) "Fluid port"
    annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
  Modelica.Units.SI.Mass m "Mass of liquid in the vessel";

protected
  final parameter Medium.ThermodynamicState state_start = Medium.setState_pTX(
      T=T_start,
      p=p_start,
      X=X_start[1:Medium.nXi]) "Medium state at start values";
  final parameter Modelica.Units.SI.Density rho_start=Medium.density(state=
      state_start) "Density, used to compute start and guess values";

  Modelica.Units.SI.Energy H "Internal energy of fluid";
  Modelica.Units.SI.Mass[Medium.nXi] mXi
    "Masses of independent components in the fluid";
  Modelica.Units.SI.Mass[Medium.nC] mC
    "Masses of trace substances in the fluid";
  Medium.ExtraProperty C[Medium.nC](nominal=C_nominal)
    "Trace substance mixture content";

initial equation
  m = V_start * rho_start;
  H = m*Medium.specificInternalEnergy(
          Medium.setState_pTX(p=p_start, T=T_start, X= X_start[1:Medium.nXi]));
  mXi = m*X_start[1:Medium.nXi];
  mC = m*C_start[1:Medium.nC];
equation
  assert(m > 1.0E-8,
    "Expansion vessel is undersized. You need to increase the value of the parameter V_start.");
  // Conservation equations
  der(m)   = port_a.m_flow;
  der(H)   = port_a.m_flow * actualStream(port_a.h_outflow);
  der(mXi) = port_a.m_flow * actualStream(port_a.Xi_outflow);
  der(mC)  = port_a.m_flow * actualStream(port_a.C_outflow);
  // Properties of outgoing flow.
  // The port pressure is set to a constant value.
  port_a.p          = p_start;
  m*port_a.h_outflow  = H;
  m*port_a.Xi_outflow = mXi;
  m*port_a.C_outflow  = mC;

   annotation (Icon(coordinateSystem(preserveAspectRatio=false,extent={{-100,
            -100},{100,100}}), graphics={
        Text(
          extent={{-148,98},{152,138}},
          textString="%name",
          textColor={0,0,255}),
        Rectangle(
          extent={{-80,80},{80,-80}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-68,70},{70,-70}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-68,18},{-68,18},{-54,32},{-28,16},{0,30},{26,16},{46,32},{
              70,18},{70,18},{70,-70},{70,-70},{-68,-70},{-68,-70},{-68,18}},
          lineColor={0,0,255},
          smooth=Smooth.Bezier,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{2,-80},{-2,-90}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid)}),
defaultComponentName="exp",
Documentation(info="<html>
<p>
This is a model of a pressure expansion vessel that allows adding or removing water.
</p>
</html>", revisions="<html>
<ul>
<li>
June 8, 2026 by Michael Wetter:<br/>
First implementation.
</li>
</ul>
</html>"));
end ExpansionVessel;
