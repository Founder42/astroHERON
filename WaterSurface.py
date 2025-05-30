import numpy as np
import matplotlib.pyplot as plt
from matplotlib import animation
from mpl_toolkits.mplot3d import Axes3D

class WaterSurface:
    def __init__(self, size=100, dt=0.1, c=1.0, damping=0.02):
        """
        Initialize the water surface simulation.
        
        Parameters:
        -----------
        size : int
            Grid size (size x size)
        dt : float
            Time step
        c : float
            Wave propagation speed
        damping : float
            Damping coefficient to simulate energy loss
        """
        self.size = size
        self.dt = dt
        self.c = c
        self.damping = damping
        
        # Initialize height maps (current, previous, and next states)
        self.current = np.zeros((size, size))
        self.previous = np.zeros((size, size))
        self.next = np.zeros((size, size))
        
    def add_disturbance(self, x, y, radius=5, amplitude=1.0):
        """Add a disturbance at position (x,y) with given radius and amplitude"""
        x_grid, y_grid = np.meshgrid(np.arange(self.size), np.arange(self.size))
        distance = np.sqrt((x_grid - x)**2 + (y_grid - y)**2)
        mask = distance < radius
        
        # Create a circular disturbance with smooth edges
        disturbance = np.zeros((self.size, self.size))
        disturbance[mask] = amplitude * (1 - distance[mask]/radius)
        
        self.current += disturbance
        self.previous += disturbance
        
    def update(self):
        """Update the water surface state using the 2D wave equation"""
        # Calculate the Laplacian using finite differences
        laplacian = (
            np.roll(self.current, 1, axis=0) + 
            np.roll(self.current, -1, axis=0) + 
            np.roll(self.current, 1, axis=1) + 
            np.roll(self.current, -1, axis=1) - 
            4 * self.current
        )
        
        # Apply wave equation: u_tt = c^2 * laplacian(u)
        # Discretized: next = 2*current - previous + c^2 * dt^2 * laplacian
        self.next = (
            2 * self.current - 
            self.previous + 
            (self.c**2) * (self.dt**2) * laplacian
        )
        
        # Apply damping
        self.next = self.next * (1 - self.damping)
        
        # Apply boundary conditions (fixed at zero)
        self.next[0, :] = self.next[-1, :] = self.next[:, 0] = self.next[:, -1] = 0
        
        # Cycle the buffers
        self.previous, self.current, self.next = self.current, self.next, self.previous
        
    def simulate(self, steps=200, x=None, y=None, radius=5, amplitude=1.0):
        """
        Run simulation for given number of steps.
        
        Parameters:
        -----------
        steps : int
            Number of simulation steps
        x, y : int or None
            Position for initial disturbance. If None, center is used.
        radius : float
            Radius of the initial disturbance
        amplitude : float
            Amplitude of the initial disturbance
        """
        # Reset simulation
        self.current = np.zeros((self.size, self.size))
        self.previous = np.zeros((self.size, self.size))
        self.next = np.zeros((self.size, self.size))
        
        # Add initial disturbance
        if x is None:
            x = self.size // 2
        if y is None:
            y = self.size // 2
        
        self.add_disturbance(x, y, radius, amplitude)
        
        # Create figure for animation
        fig = plt.figure(figsize=(10, 8))
        ax = fig.add_subplot(111, projection='3d')
        
        x_grid, y_grid = np.meshgrid(np.arange(self.size), np.arange(self.size))
        surface = ax.plot_surface(x_grid, y_grid, self.current, cmap='viridis', 
                                  vmin=-amplitude, vmax=amplitude)
        
        def init():
            ax.clear()
            surface = ax.plot_surface(x_grid, y_grid, self.current, cmap='viridis',
                                     vmin=-amplitude, vmax=amplitude)
            ax.set_zlim(-amplitude, amplitude)
            ax.set_title('Water Surface Ripples')
            ax.set_xlabel('X')
            ax.set_ylabel('Y')
            ax.set_zlabel('Height')
            return surface,
        
        def animate(i):
            ax.clear()
            self.update()
            surface = ax.plot_surface(x_grid, y_grid, self.current, cmap='viridis',
                                     vmin=-amplitude, vmax=amplitude)
            ax.set_zlim(-amplitude, amplitude)
            ax.set_title(f'Water Surface Ripples - Step {i}')
            ax.set_xlabel('X')
            ax.set_ylabel('Y')
            ax.set_zlabel('Height')
            return surface,
        
        anim = animation.FuncAnimation(fig, animate, init_func=init, 
                                       frames=steps, interval=50, blit=False)
        
        plt.tight_layout()
        plt.show()
        
        return anim


if __name__ == "__main__":
    # Create a water surface simulation
    water = WaterSurface(size=50, dt=0.1, c=2.0, damping=0.01)
    
    # Run the simulation with a disturbance at the center
    water.simulate(steps=100, amplitude=2.0, radius=3)
