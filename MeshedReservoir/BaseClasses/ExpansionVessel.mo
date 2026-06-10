within MeshedReservoir.BaseClasses;
model ExpansionVessel "ExpansionVessel"
  replaceable package Medium =
    Modelica.Media.Interfaces.PartialMedium "Medium model for water volume"
      annotation (choicesAllMatching = true);
  replaceable package MediumAir =
    Modelica.Media.Interfaces.PartialMedium "Medium model for air volume"
      annotation (choicesAllMatching = true);

  parameter Modelica.Units.SI.Volume VTot
    "Total volume of the vessel";
  parameter Modelica.Units.SI.Volume VWat_start = VTot/2
    "Volume of liquid stored in the vessel at the start of the simulation";

  // Water volume parameters
  parameter Modelica.Units.SI.Temperature T_start = Medium.T_default
    "Start value of temperature"
    annotation(Dialog(tab = "Initialization"));
  parameter Modelica.Units.SI.AbsolutePressure p_start = Medium.p_default
    "Start value of pressure"
    annotation(Dialog(tab = "Initialization"));

  final parameter Modelica.Units.SI.Mass mAir_start = (VTot - VWat_start) * rhoAir_start
    "Initial mass of air";
  final parameter Modelica.Units.SI.Mass mWat_start = VWat_start * rhoWat_start
    "Initial mass of water";
  final parameter Modelica.Units.SI.Mass mTot_start = mAir_start + mWat_start
    "Initial mass of water and air";

  Modelica.Fluid.Interfaces.FluidPort_a portWat(
    redeclare package Medium = Medium) "Fluid port for water"
    annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
  Modelica.Fluid.Interfaces.FluidPort_a portAir(
    redeclare package Medium = MediumAir) "Fluid port for air"
    annotation (Placement(transformation(extent={{-10,90},{10,110}})));
  Modelica.Blocks.Interfaces.RealOutput m(unit="kg") "Total mass of water and air"
    annotation (Placement(transformation(extent={{100,-70},{120,-50}}),
        iconTransformation(extent={{100,-100},{120,-80}})));
  Modelica.Blocks.Interfaces.RealOutput p(
    unit="Pa",
    displayUnit="Pa",
    nominal=p_start,
    stateSelect=StateSelect.prefer) "Air pressure in vessel"
    annotation (Placement(transformation(extent={{100,50},{120,70}})));
  Modelica.Units.SI.Mass mWat(
    stateSelect=StateSelect.always,
    nominal=mWat_start) "Mass of water in the vessel";
  Modelica.Units.SI.Mass mAir(
    stateSelect=StateSelect.avoid) "Mass of air in the vessel";
  Modelica.Units.SI.Volume VWat "Volume of water in the vessel";
  Modelica.Units.SI.Volume VAir "Volume of air in the vessel";
  Real hNor = VWat / VTot "Normalized height of water level";

protected
  constant Modelica.Units.SI.SpecificHeatCapacity RAir = 287.05
    "Specific gas constant for air";

  parameter Modelica.Units.SI.MassFraction X_start[Medium.nX] = Medium.X_default
    "Start value of mass fractions m_i/m for water volume"
    annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0));
  parameter Medium.ExtraProperty C_start[Medium.nC](
    final quantity=Medium.extraPropertiesNames)=fill(0, Medium.nC)
    "Start value of trace substances for water volume"
    annotation (Dialog(tab="Initialization", enable=Medium.nC > 0));
  parameter Medium.ExtraProperty C_nominal[Medium.nC](
    final quantity=Medium.extraPropertiesNames) = fill(1E-2, Medium.nC)
    "Nominal value of trace substances for water volume. (Set to typical order of magnitude.)"
    annotation (Dialog(tab="Advanced", enable=Medium.nC > 0));

  // Volume parameters
  final parameter Medium.ThermodynamicState stateWat_start = Medium.setState_pTX(
      T=T_start,
      p=p_start,
      X=X_start[1:Medium.nXi]) "Water medium state at start values";
  final parameter Modelica.Units.SI.Density rhoWat_start=Medium.density(state=
      stateWat_start) "Water density, used to compute start and guess values";

  final parameter MediumAir.ThermodynamicState stateAir_start = MediumAir.setState_pTX(
      T=T_start,
      p=p_start,
      X=MediumAir.X_default) "Air medium state at start values";
  final parameter Modelica.Units.SI.Density rhoAir_start=MediumAir.density(state=
      stateAir_start) "Air density, used to compute start and guess values";

  parameter Modelica.Units.SI.Height h = 1.5
    "Approximate height of the vessel, used to compute an approximate surface area for heat transfer calculations";
  parameter Modelica.Units.SI.Area A = VTot/h
    "Approximate surface area of water";
  parameter Modelica.Units.SI.CoefficientOfHeatTransfer hCon = 5
    "Convective heat transfer coefficient";

  Modelica.Units.SI.Energy HWat "Internal energy of water";
  Modelica.Units.SI.Mass[Medium.nXi] mXiWat
    "Masses of independent components in the water";
  Modelica.Units.SI.Mass[Medium.nC] mCWat
    "Masses of trace substances in the water";
  Modelica.Units.SI.Energy HAir "Internal energy of air";
  Modelica.Units.SI.Mass[MediumAir.nXi] mXiAir
    "Masses of independent components in the air";
  Modelica.Units.SI.Mass[MediumAir.nC] mCAir
    "Masses of trace substances in the air";
  Medium.ExtraProperty C[Medium.nC](nominal=C_nominal)
    "Trace substance mixture content";
  MediumAir.ExtraProperty CAir[MediumAir.nC](nominal=fill(1E-2, MediumAir.nC))
    "Trace substance mixture content for air";

  Modelica.Units.SI.Density rhoWat "Actual density of water";
  Modelica.Units.SI.Temperature TWat "Temperature of water";
  Modelica.Units.SI.Temperature TAir "Temperature of air";
  Medium.ThermodynamicState stateWat "Thermodynamic state of water";
  MediumAir.ThermodynamicState stateAir "Thermodynamic state of air";
  Modelica.Units.SI.HeatFlowRate QWatToAir_flow "Heat flow rate from water to air";

initial equation
  // Water
  TWat = T_start;
  TWat = TAir;
  mXiWat = mWat*X_start[1:Medium.nXi];
  mCWat = mWat*C_start[1:Medium.nC];
  // Air
  mAir = mAir_start;
  mXiAir = mAir*MediumAir.X_default[1:MediumAir.nXi];
  mCAir = fill(0, MediumAir.nC);
  portAir.p = p_start;
equation
  // Outputs
  m = mWat + mAir;
  p = portAir.p;

  assert(hNor > 0.01 and hNor < 0.99,
    "In " + getInstanceName() + ": Expansion vessel is undersized. Normalized water level is hNor = " + String(hNor) + ".
   You need to increase the value of the parameter VTot.");

  // Thermodynamic states
  stateWat = Medium.setState_phX(
    p=portWat.p,
    h=HWat/mWat,
    X=mXiWat/mWat);
  stateAir = MediumAir.setState_phX(
    p=portAir.p,
    h=HAir/mAir,
    X=mXiAir/mAir);

  // Temperatures
  TWat = Medium.temperature(stateWat);
  TAir = MediumAir.temperature(stateAir);

  // Volume calculations
  rhoWat = Medium.density(stateWat);
  VWat = mWat / rhoWat;
  VAir = VTot - VWat;

  // Ideal gas law for air: p*V = m*R_s*T, where R_s = R/M (specific gas constant)
  portAir.p * VAir = mAir * RAir * TAir;

  // Heat transfer from water to air
  QWatToAir_flow = hCon * A * (TWat - TAir);

  // Conservation equations for water
  der(mWat)   = portWat.m_flow;
  der(HWat)   = portWat.m_flow * actualStream(portWat.h_outflow) - QWatToAir_flow;
  der(mXiWat) = portWat.m_flow * actualStream(portWat.Xi_outflow);
  der(mCWat)  = portWat.m_flow * actualStream(portWat.C_outflow);
  // Conservation equations for air
  der(mAir)   = portAir.m_flow;
  der(HAir)   = portAir.m_flow * actualStream(portAir.h_outflow) + QWatToAir_flow;
  der(mXiAir) = portAir.m_flow * actualStream(portAir.Xi_outflow);
  der(mCAir)  = portAir.m_flow * actualStream(portAir.C_outflow);
  // Properties of outgoing flow.
  // The water port pressure is set to the air port pressure.
  portWat.p          = portAir.p;
  mWat*portWat.h_outflow  = HWat;
  mWat*portWat.Xi_outflow = mXiWat;
  mWat*portWat.C_outflow  = mCWat;
  mAir*portAir.h_outflow  = HAir;
  mAir*portAir.Xi_outflow = mXiAir;
  mAir*portAir.C_outflow  = mCAir;

   annotation (Icon(coordinateSystem(preserveAspectRatio=false,extent={{-100,
            -100},{100,100}}), graphics={
        Text(
          extent={{20,94},{96,138}},
          textString="%name",
          textColor={0,0,255}),
        Rectangle(
          extent={{-60,80},{60,-80}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{2,-80},{-2,-90}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{2,90},{-2,80}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,140,72},
          fillPattern=FillPattern.Solid),
        Line(points={{100,60},{50,60}}, color={0,0,0}),
        Line(points={{100,-90},{50,-90}}, color={0,0,0}),
        Line(points={{50,-90},{50,-80}}, color={0,0,0}),
        Text(
          extent={{62,94},{96,66}},
          textColor={0,0,255},
          textString="p"),
        Text(
          extent={{26,-34},{60,-62}},
          textColor={0,0,255},
          textString="p"),
        Text(
          extent={{64,-58},{98,-86}},
          textColor={0,0,255},
          textString="m"),
        Rectangle(
          extent={{-50,70},{50,-70}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-50,DynamicSelect(0, -70 + 140*hNor)},{50,-70}},
          lineColor={0,0,0},
          fillColor={28,108,200},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None)}),
defaultComponentName="exp",
Documentation(info="<html>
<p>
This is a model of a pressure expansion vessel that allows adding or removing water and air.
The vessel contains two fluid zones: a liquid water zone and a gaseous air zone.
</p>
<h4>Main Physics</h4>
<p>
The model implements the following physics:
</p>
<ul>
<li>
<b>Volume partitioning:</b> The total vessel volume <code>VTot</code> is divided between
water volume <code>VWat</code> and air volume <code>VAir</code>, where
<code>VWat + VAir = VTot</code>. The water volume is computed from the water mass
and density.
</li>
<li>
<b>Pressure coupling:</b> The water and air pressures are equal (<code>portWat.p = portAir.p</code>),
representing mechanical equilibrium at the water-air interface.
</li>
<li>
<b>Ideal gas law:</b> The air volume follows the ideal gas law
<code>p·VAir = mAir·RAir·TAir</code>, where <code>RAir = 287.05 J/(kg·K)</code>
is the specific gas constant for air.
</li>
<li>
<b>Mass conservation:</b> Separate mass balance equations for water and air, tracking
mass flows through the respective ports and accounting for species transport.
</li>
<li>
<b>Energy conservation:</b> Separate energy balance equations for water and air,
including enthalpy flows and heat transfer between the two zones.
</li>
<li>
<b>Heat transfer:</b> Convective heat transfer between water and air is modeled as
<code>QWatToAir_flow = hCon·A·(TWat - TAir)</code>, where the surface area <code>A</code>
and heat transfer coefficient <code>hCon</code> are approximated from the vessel geometry.
</li>
</ul>
<p>
The model includes an assertion to warn if the vessel becomes too full or too empty
(outside the range of 1% to 99% water volume), indicating undersizing.
</p>
</html>", revisions="<html>
<ul>
<li>
June 9, 2026 by Michael Wetter:<br/>
Added documentation of main physics and modeling approach.
</li>
<li>
June 8, 2026 by Michael Wetter:<br/>
First implementation.
</li>
</ul>
</html>"));
end ExpansionVessel;
