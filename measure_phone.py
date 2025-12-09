import numpy as np
from stl import mesh
import os

def measure():
    stl_path = "reference/iphone-12-mini.stl"
    if not os.path.exists(stl_path):
        print(f"Error: {stl_path} not found")
        return

    # Load the mesh
    print(f"Loading {stl_path}...")
    my_mesh = mesh.Mesh.from_file(stl_path)
    
    # Original bounds
    minx, maxx = my_mesh.x.min(), my_mesh.x.max()
    miny, maxy = my_mesh.y.min(), my_mesh.y.max()
    minz, maxz = my_mesh.z.min(), my_mesh.z.max()
    
    print(f"Original Bounds:")
    print(f"X: {minx:.2f} to {maxx:.2f}")
    print(f"Y: {miny:.2f} to {maxy:.2f}")
    print(f"Z: {minz:.2f} to {maxz:.2f}")

    # OpenSCAD: rotate([0, 90, 0])
    # Rotates 90 deg around Y axis.
    # Formula:
    # x' = z
    # y' = y
    # z' = -x
    
    # We can transform all points in the mesh vectors
    # my_mesh.vectors is shape (num_faces, 3, 3)
    # We can just transform the flattened points for bounds calculation
    
    all_points = my_mesh.vectors.reshape(-1, 3)
    
    # Apply rotation
    # New X is Old Z
    # New Y is Old Y
    # New Z is -Old X
    
    rotated_points = np.zeros_like(all_points)
    rotated_points[:, 0] = all_points[:, 2]        # x' = z
    rotated_points[:, 1] = all_points[:, 1]        # y' = y
    rotated_points[:, 2] = -all_points[:, 0]       # z' = -x
    
    rmin_x, rmax_x = rotated_points[:, 0].min(), rotated_points[:, 0].max()
    rmin_y, rmax_y = rotated_points[:, 1].min(), rotated_points[:, 1].max()
    rmin_z, rmax_z = rotated_points[:, 2].min(), rotated_points[:, 2].max()
    
    print(f"\nRotated ([0, 90, 0]) Bounds (as per iphone_ref module):")
    print(f"X: {rmin_x:.2f} to {rmax_x:.2f}")
    print(f"Y: {rmin_y:.2f} to {rmax_y:.2f}")
    print(f"Z: {rmin_z:.2f} to {rmax_z:.2f}")
    
    # Determine the "top" of the phone
    # Usually the top of the phone is the furthest point from the center/charging port
    # If the phone is centered, it might be symmetric.
    # The user wants the guide to touch the "top".
    # My top_guide extends in Negative X.
    # So we are looking for the Minimum X value? 
    # Or assuming the phone is centered at 0,0,0?
    
    print(f"\nPotential guide offsets:")
    print(f"Max X (Right side?): {rmax_x:.2f}")
    print(f"Min X (Left side?): {abs(rmin_x):.2f} (Absolute value)")

if __name__ == "__main__":
    measure()
