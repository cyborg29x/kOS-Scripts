// -- Manual launch helper --
clearscreen.
sas off.

// -- Function list --
set adaptiveK to {
	if pid:error < 1 {
		set pid:kI to 0.1.
		set pid:kD to 0.
	}
	else {
		set pid:kI to 0.
		set pid:kD to 0.
		pid:reset().
	}
}.
set headingCorrectiveDir to {
	if orbitInclination >= 175 and orbit:inclination < 90 {
		return 270.
	}
	else if inclinationHemisphereButton:text = "N" {
		adaptiveK().
		return headingDir - pid:update(time:seconds, orbit:inclination).
	}
	else {
		adaptiveK().
		return headingDir + pid:update(time:seconds, orbit:inclination).
	}
}.

// -- GUI code --
set gui to GUI(220).
set gui:x to 200.
set gui:y to 200.
set guiTitle to gui:addLabel("<b>MANUAL LAUNCH HELPER</b>").
set guiTitle:style:align to "center".
set guiTitle:style:fontSize to 14.

set spacer1 to gui:addSpacing(25).
set inclinationSetFieldSubtitle to gui:addLabel("Desired orbital inclination:").
set box1 to gui:addHLayout.
set inclinationSetField to box1:addTextField.
set inclinationHemisphereButton to box1:addButton("N").
set inclinationHemisphereButton:style:width to 25.
set inclinationHemisphereButton:onClick to {
	if inclinationHemisphereButton:text = "N" {
		set inclinationHemisphereButton:text to "S".
	}
	else {
		set inclinationHemisphereButton:text to "N".
	}
}.
set box2 to gui:addHLayout.
set orbitInclination to 0.
set currentInclination to box2:addLabel("Currently set to " + orbitInclination + " " + inclinationHemisphereButton:text).
set inclinationSetButton to box2:addButton("SET").
set inclinationSetButton:style:width to 50.
set inclinationSetButton:onClick to {
	if inclinationSetField:text:toScalar(0.000999) <> 0.000999 {
		set orbitInclination to inclinationSetField:text:toScalar.
		set pid:setpoint to orbitInclination.
		set currentInclination:text to "Currently set to " + min(180, max(0, orbitInclination)) + " " + inclinationHemisphereButton:text.
		if inclinationHemisphereButton:text = "N" {
			set headingDir to 90 - min(180, max(0, orbitInclination)).
		}
		else {
			set headingDir to 90 + min(180, max(0, orbitInclination)).
		}
		set inclinationSetField:text to "".
	}
}.

set spacer2 to gui:addSpacing(25).
set modeSelectionSubtitle to gui:addLabel("Mode of operation:").
set box3 to gui:addVLayout.
set gravTurnButton to box3:addRadioButton("Gravity turn", true).
set gravTurnButton:onToggle to {
	parameter val.
	if val {
		set opMode to 0.
	}
}.
set zeroPitchButton to box3:addRadioButton("Zero pitch", false).
set zeroPitchButton:onToggle to {
	parameter val.
	if val {
		set opMode to 1.
	}
}.


set spacer3 to gui:addSpacing(25).
set closeButton to gui:addButton("END PROGRAM").
set closeButton:onClick to {gui:hide(). sas on. set stopQuery to 1.}.
gui:show().

// -- PID loop code --
set pid to pidLoop().
set pid:kP to 2.
set pid:minOutput to -5.
set pid:maxOutput to 5.
set pid:setpoint to 0.

set stopQuery to 0.
set pitchDir to 90.
set headingDir to 90.
set pitchOffset to 0.

// -- Main code --
lock steering to heading(headingCorrectiveDir(), pitchDir).
wait until ship:control:pilotPitch <> 0 or stopQuery = 1.

until stopQuery = 1 {
	set pitchOffset to min(5, max(-5, pitchOffset + ship:control:pilotPitch * 0.02)).
	set velocityPitch to 90 - vectorAngle(up:vector, ship:velocity:surface).
	if opMode = 1 {
		set pitchDir to 0.
	}
	else {
		set pitchDir to velocityPitch + pitchOffset.
	}
}
