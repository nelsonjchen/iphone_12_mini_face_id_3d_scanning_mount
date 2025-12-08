// Simplified Mount View

// 1. The "Mount" (Just a cube for now)
module iphone_ref() {
  rotate([0, 90, 0])
    import("reference/iphone-12-mini.stl");
}

// 1. The "Mount" (Just a cube for now)
module mirror_slot() {
  mirror_w = 70.0;
  mirror_th = 2.0; // Slightly thicker for slot ease
  mirror_h = 70.0; // Visual height

  tolerance = 0.5;
  slot_w = mirror_th + tolerance;

  // Pillars to hold the mirror
  pillar_w = 5; // Width of the side walls
  pillar_d = 20; // Depth of the pillar
  pillar_h = 20; // Height to support the mirror

  // Separation between pillars (Mirror width + tolerance)
  separation = mirror_w + tolerance;

  difference() {
    union() {
      // Left Pillar - Moved back to support mirror
      translate([-15, (separation + pillar_w) / 2, pillar_h / 2])
        cube([pillar_d, pillar_w, pillar_h], center=true);

      // Right Pillar - Moved back to support mirror
      translate([-15, -(separation + pillar_w) / 2, pillar_h / 2])
        cube([pillar_d, pillar_w, pillar_h], center=true);
    }

    // The Slot Cut
    // 45 degree angle for the mirror
    // Center at [-24.75, 0, 24.75] puts bottom edge at [0,0,0]
    translate([-24.75, 0, 24.75])
      rotate([0, -45, 0])
        cube([slot_w, separation + pillar_w * 2 + 2, 80], center=true);
  }
}

// 1. The "Mount" (Just a cube for now)
difference() {
  color("skyblue") {
    union() {
      // Base - Widened for 70mm mirror
      // Extended back (-X) to support the shifted pillars
      translate([-10, 0, -5])
        cube([40, 82, 15], center=true);

      // Mirror Slot Assembly
      translate([0, 0, 0]) // Pillars are now positioned absolutely relative to base Z=0
        mirror_slot();
    }
  }

  // Profile Cutout
  // Projects the phone's X-axis profile and extrudes it to create a cutter
  translate([0, 0, 0])
    rotate([0, -90, 0]) // Rotate back to X axis alignment
      linear_extrude(height=60, center=true)
        projection(cut=false)
          rotate([0, 90, 0]) // Rotate to Z for projection (captures X profile)
            iphone_ref();

  // Face ID Clearance Cut
  // Removing more material to ensure clear view
  // 18mm wide (leaving 1mm walls on 20mm mount)
  // Deeper cut to verify clearance
  translate([0, 0, 10]) // Positioned to cut the top wall
    cube([30, 55, 30], center=true);

  // Bottom Cleaner Cut
  // Slices off anything protruding below the base (Base bottom is at Z = -5 - 7.5 = -12.5)
  translate([0, 0, -50 - 12.5])
    cube([100, 100, 100], center=true);
}

// 2. The iPhone 12 Mini Reference
// Orange, transparent
// Rotated -90 on X based on previous preview.scad hints to make it lay flat
%color("orange", 0.5)
  iphone_ref();

// 3. The Mirror (Visual only)
// 70x70mm
// Placed IN the slot position to visualize
%color("silver")
  translate([-24.75, 0, 24.75]) // Center offset for bottom at 0,0
    rotate([0, -45, 0])
      cube([1, 70.0, 70.0], center=true);
