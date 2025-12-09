// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

// Mirror Dimensions
// Mirror Dimensions
mirror_width = 75.2;
mirror_thickness = 1; // Slightly thicker for slot ease

mirror_tolerance = 0.25;
mirror_length_tolerance = 0.5;

mirror_slot_thickness = mirror_thickness + mirror_tolerance;
mirror_slot_length = mirror_width + mirror_length_tolerance;

// Fit Dimensions
phone_fit_tolerance = 0.25;
guide_offset = 22; // Distance to the top of the phone guide

// Mount Geometry
mount_width = 80;
mount_thickness = 20;
mirror_slot_width = mirror_width + mirror_tolerance;
mount_angle = 45;

// Cutout Dimensions
face_id_cut_w = 30;
face_id_cut_h = 30;
face_id_cut_d = 60;

// -----------------------------------------------------------------------------
// Modules
// -----------------------------------------------------------------------------

module iphone_ref() {
  // Natural top of phone is at X = -14
  // We want top of phone to be at X = -guide_offset
  // Shift = (-guide_offset) - (-14) = 14 - guide_offset
  shift_x = 14 - guide_offset;

  translate([shift_x, 0, 0])
    rotate([0, 90, 0])
      import("reference/iphone-12-mini.stl");
}

module mount_base() {
  color("skyblue") {
    union() {
      // Base - Widened for 70mm mirror
      // Extended back (-X) to support the shifted pillars
      translate([-5, 0, -5])
        cube([mount_thickness, mount_width, 15], center=true);

      // Angled support for the mirror, pushing up
      rotate([0, -mount_angle, 0])
        translate([-2, 0, 5])
          cube([6, mount_width, 7], center=true);
      // Angled support for the mirror, pushing down
      difference() {
        rotate([0, -mount_angle, 0])
          translate([0, 0, 5])
            cube([5, mount_width, 7], center=true);
        rotate([0, -mount_angle, 0])
          translate([0, 0, 5])
            cube([5, mount_width - 8, 7], center=true);
      }
    }
  }
}

module top_guide() {
  // Adds a guide/stop for the top of the phone
  // Central spine extending from the mount base to the stopper (Negative X direction)
  // "Jut out the base" along the center, then "straight up"

  spine_width = 10;
  // Mount base is translate([-5, 0, -5]) cube([20...]) -> X range [-15, 5]
  base_Left_X = -15;

  // Height Logic:
  // Base Bottom: -12.5
  // Phone Top: 0
  // Target: Guide extends from -12.5 to 0. 
  // Height = 12.5. Center = -6.25.

  g_height = 12.5;
  g_center_z = -6.25;

  // only draw if sticking out
  if (guide_offset > abs(base_Left_X)) {
    color("cornflowerblue")
      union() {
        // 1. The Central Spine ("Jut out the base")
        // Extends from base edge (-15) to guide_offset
        // Aligned with Z range [-12.5, 0]
        translate([(base_Left_X - guide_offset) / 2, 0, g_center_z])
          cube([guide_offset - abs(base_Left_X) + 0.1, spine_width, g_height], center=true);

        // 2. The Vertical Stop ("Straight up")
        // Stays within the Z limit (0) to match "cut off anything above z=0"
        // But ensures it blocks the phone face (Z -9.4 to 0)
        translate([-guide_offset - 1.5, 0, g_center_z])
          cube([3, spine_width, g_height], center=true);
      }
  }
}

module mirror_cutout() {
  // Calculate offsets to place the bottom corner at [0,0,0]
  // Rotated -45 deg: z_min is at local x=-w/2, z=-h/2
  z_offset = (mirror_slot_length + mirror_slot_thickness) * sin(mount_angle) / 2;
  x_offset = (mirror_slot_length - mirror_slot_thickness) * sin(mount_angle) / 2;

  translate([-x_offset, 0, z_offset])
    rotate([0, -mount_angle, 0])
      cube([mirror_slot_thickness, mirror_slot_width, mirror_slot_length], center=true);
}

module profile_cutter() {
  // Projects the phone's X-axis profile and extrudes it to create a cutter
  // Added offset for tolerance
  translate([0, 0, 0])
    rotate([0, -90, 0]) // Rotate back to X axis alignment
      linear_extrude(height=60, center=true)
        offset(delta=phone_fit_tolerance)
          projection(cut=false)
            rotate([0, 90, 0]) // Rotate to Z for projection (captures X profile)
              iphone_ref();
}

module face_id_cutter() {
  // Removing more material to ensure clear view
  // 18mm wide (leaving 1mm walls on 20mm mount)
  // Deeper cut to verify clearance
  translate([0, 0, 10]) // Positioned to cut the top wall
    cube([face_id_cut_w, face_id_cut_d, face_id_cut_h], center=true);
}

module side_trimmer() {
  // Tapers the ends of the mount (Y-axis) to reduce bulk without cutting the mirror slot.
  // "Opposite" taper: Wide at the TOP, Narrow at the BOTTOM.
  // This preserves the mirror slot wall at the top.

  safe_y = 40; // Pivot at the outer edge (40mm = 80mm width)
  angle = 15;

  // Pivot Z: effectively the point where the taper "starts" moving inwards as we go down.
  // If we pivot at a high point (e.g. z=40), everything below gets cut.
  // If we pivot at z=0, bottom gets cut, top is safe.
  pivot_z = 0;

  // Positive Y Taper (Top side in 2D view)
  // We want to cut the bottom (negative Z relative to pivot? No, absolute Z).
  // Rotate -15 deg: 
  //   Top (+Z) moves +Y (Away -> Safe)
  //   Bottom (-Z) moves -Y (In -> Cut)
  translate([0, safe_y, pivot_z])
    rotate([-angle, 0, 0])
      translate([0, 50, 0])
        cube([100, 100, 200], center=true);

  // Negative Y Taper (Bottom side in 2D view)
  // Rotate +15 deg:
  //   Top (+Z) moves -Y (Away -> Safe)
  //   Bottom (-Z) moves +Y (In -> Cut)
  translate([0, -safe_y, pivot_z])
    rotate([angle, 0, 0])
      translate([0, -50, 0])
        cube([100, 100, 200], center=true);
}

// -----------------------------------------------------------------------------
// Main Assembly
// -----------------------------------------------------------------------------

difference() {
  union() {
    // Base Logic: Cut by X-profile (profile_cutter)
    difference() {
      mount_base();
      profile_cutter();
    }

    // Guide Logic: Subtract the phone 3D model with tolerance scale
    difference() {
      top_guide();
      iphone_tolerance_cutter();
      sensor_patch();
    }
  }

  // Common cuts
  mirror_cutout();
  face_id_cutter();
  side_trimmer();
  bottom_label();
}

module iphone_tolerance_cutter() {
  // Creates a slightly larger version of the iphone_ref for cutting
  // Scaling is used to simulate tolerance since minkowski is too slow for STLs

  // Measured Dimensions (approx)
  p_len = 131.5; // Z in STL
  p_wid = 65.2; // Y in STL
  p_thk = 9.4; // X in STL

  tol = phone_fit_tolerance;

  // Scale factors for each original axis
  s_len = (p_len + 2 * tol) / p_len;
  s_wid = (p_wid + 2 * tol) / p_wid;
  s_thk = (p_thk + 2 * tol) / p_thk;

  // Center of the STL geometry (Local coords)
  // X: 0 to 9.4 -> 4.7
  // Y: -32.6 to 32.6 -> 0
  // Z: -14 to 117.5 -> 51.75
  c_x = 4.7;
  c_y = 0;
  c_z = 51.75;

  shift_x = 14 - guide_offset;

  translate([shift_x, 0, 0])
    rotate([0, 90, 0])
      translate([c_x, c_y, c_z])
        scale([s_thk, s_wid, s_len])
          translate([-c_x, -c_y, -c_z])
            import("reference/iphone-12-mini.stl");
}

module sensor_patch() {
  // Removes any material that "leaks" into the notch area
  // (i.e. where the phone has a void, so the subtraction doesn't remove the guide material)
  // Located centered on Y, near the top edge X.

  // Notch width approx 35mm.
  patch_w = 40;

  translate([-guide_offset + 5, 0, 0]) // Start at guide offset and cut inwards (+X)
    cube([10, patch_w, 10], center=true);
}

module bottom_label() {
  // Engrave text on the bottom face
  // Bottom face is at Z = -12 (center -5, half-height 7)
  // Text runs along the Y axis
  translate([-5, 0, -13.01]) // Slight offset to ensure clean cut surface
    rotate([0, 0, 90])
      mirror([1, 0, 0])
        linear_extrude(height=0.6) {
          translate([0, 3.5, 0])
            text("iPhone 12 mini", size=5, valign="center", halign="center");
          translate([0, -3.5, 0])
            text("Face ID 3D Scan Mount", size=4.5, valign="center", halign="center");
        }
}

// -----------------------------------------------------------------------------
// Visual References (Not part of the physical model)
// -----------------------------------------------------------------------------

// iPhone 12 Mini Reference
// Orange, transparent
// Rotated -90 on X based on previous preview.scad hints to make it lay flat
%color("orange", 0.5)
  iphone_ref();

// Mirror (Visual only)
// Placed IN the slot position to visualize
%color("silver") {
  z_offset_vis = (mirror_width + mirror_thickness) * sin(mount_angle) / 2;
  // Note: This visual placement logic might need tweaking if the slot logic changes perfectly,
  // but relying on the same math as the cutout usually works.
  // The original generic offset was:
  // translate([-(70 - 1) * sin(45) / 2, 0, (70 + 1) * sin(45) / 2])

  // Adapted to variables:
  translate([-(mirror_width - mirror_thickness) * sin(mount_angle) / 2, 0, (mirror_width + mirror_thickness) * sin(mount_angle) / 2])
    rotate([0, -mount_angle, 0])
      cube([mirror_thickness, mirror_width, mirror_width], center=true);
}
