import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const messages = [
	// Short
	"Spinning up...",
	"Calibrating...",
	"Localizing...",
	"Homing...",
	"Actuating...",
	"Servoing...",
	"Whirring...",
	"Clunking...",
	"Torquing...",
	"Damping...",
	"Meshing...",
	"Bootstrapping...",
	"Cogitating...",
	"Percolating...",
	"Ruminating...",
	"Noodling...",
	"Tinkering...",
	"Fiddling...",
	"Wrangling...",
	"Pondering...",

	// Control
	"Tuning the PID until it stops oscillating...",
	"Adding derivative gain and regretting it...",
	"Linearizing around the operating point...",
	"Discretizing the continuous dynamics...",
	"Picking Q and R by vibes...",
	"Closing the loop, gently...",
	"Checking the phase margin...",
	"Saturating the actuator on purpose...",
	"Compensating for gravity...",
	"Backing off from the joint limit...",
	"Zeroing the force sensor...",
	"Estimating the payload mass...",
	"Waiting for the step response to settle...",
	"Reducing the timestep until it stops exploding...",
	"Blaming the integrator...",

	// Estimation
	"Letting the Kalman filter converge...",
	"Propagating covariance forward...",
	"Asking the IMU to please stop drifting...",
	"Reconciling odometry with reality...",
	"Filtering noise out of the encoder ticks...",
	"Rejecting outliers with RANSAC...",
	"Registering two point clouds that disagree...",
	"Voxelizing the world...",
	"Closing the loop on SLAM...",
	"Recovering from the kidnapped robot problem...",
	"Waiting for the lidar to spin up...",
	"Synchronizing timestamps across sensors...",
	"Blaming the clock skew...",

	// Kinematics
	"Normalizing the quaternion again...",
	"Converting Euler angles and immediately regretting it...",
	"Fighting the gimbal lock...",
	"Inspecting the Jacobian for singularities...",
	"Solving inverse kinematics with mild optimism...",
	"Rotating the frame the other way...",
	"Right-hand-ruling it out...",
	"Checking the sign convention...",
	"Fixing the units, again...",
	"Converting degrees to radians for the third time...",
	"Naming a frame something honest...",

	// Planning
	"Inflating the costmap...",
	"Sampling the configuration space...",
	"Growing an RRT toward the goal...",
	"Smoothing the trajectory...",
	"Explaining to the planner that the wall is not optional...",
	"Replanning around a chair...",
	"Warming up the solver...",
	"Waiting for the optimizer to admit defeat...",
	"Grasping and hoping friction cooperates...",

	// ROS
	"Sourcing the workspace one more time...",
	"Running colcon build and hoping...",
	"Rebuilding everything after touching one header...",
	"Chasing a dangling symlink through the install space...",
	"Waiting for the transform to become available...",
	"Looking up tf2 between base_link and map...",
	"Remapping topics until they line up...",
	"Waiting for the node to reach the active state...",
	"Publishing to a topic nobody subscribes to...",
	"Discovering nodes over DDS...",
	"Blaming the middleware...",
	"Checking whether the E-stop is still pressed...",
	"Powering the motors back on, carefully...",

	// Hardware
	"Reading the datasheet properly this time...",
	"Bit-banging the protocol...",
	"Waiting on the CAN bus...",
	"Poking the serial port...",
	"Power cycling and pretending that is a fix...",
	"Reseating the connector...",

	// Humanoids
	"Keeping the ZMP inside the support polygon...",
	"Chasing the capture point...",
	"Regulating centroidal momentum...",
	"Planning where the next foot goes...",
	"Negotiating with the contact schedule...",
	"Solving the whole-body QP...",
	"Spending the ankle torque wisely...",
	"Shifting weight onto the stance leg...",
	"Recovering from a shove nobody asked for...",
	"Falling gracefully, or at least cheaply...",
	"Standing back up, again...",
	"Bracing before the heel strike...",
	"Tuning the gait until it stops limping...",
	"Waiting for the double support phase...",
	"Retargeting motion capture onto shorter legs...",
	"Following the reference motion, loosely...",
	"Explaining to the robot that the floor is flat...",
	"Trusting the torso IMU more than it deserves...",
	"Backing away from the knee singularity...",
	"Checking the harness is still attached...",
	"Asking the operator to clear the workspace...",
	"Warming up the actuators...",
	"Listening for the harmonic drive to complain...",
	"Balancing on one foot, briefly...",

	// Reinforcement learning
	"Rolling out one more episode...",
	"Resetting the environment...",
	"Filling the replay buffer...",
	"Stepping ten thousand envs at once...",
	"Waiting for the reward curve to go up...",
	"Shaping the reward until it stops cheating...",
	"Watching the policy discover a bug in the physics...",
	"Penalizing the behavior I forgot to penalize...",
	"Clipping the surrogate objective...",
	"Estimating advantages with some optimism...",
	"Fitting the value function to noise...",
	"Turning up the entropy bonus...",
	"Watching KL divergence spike and panicking...",
	"Annealing the learning rate...",
	"Advancing the terrain curriculum...",
	"Randomizing friction and hoping...",
	"Crossing the reality gap...",
	"Overfitting to the simulator...",
	"Training a policy that only works indoors...",
	"Simulating in Gazebo, doubting the physics...",
	"Waiting on Isaac to allocate the environments...",
	"Watching the arm swing wildly in sim...",
	"Collecting the first million steps...",
	"Rerunning with three seeds...",
	"Refreshing tensorboard for no reason...",
	"Blaming the seed...",
	"Reading the loss and pretending it is fine...",
	"Computing error bars honestly...",

	// Python
	"Waiting on numpy to broadcast...",
	"Vectorizing the loop out of shame...",
	"Guessing which axis to sum over...",
	"Reshaping until the dimensions agree...",
	"Squeezing out a stray dimension...",
	"Moving the tensor to the right device...",
	"Reconciling conda with pip...",
	"Reading the traceback from the bottom...",
	"Appeasing the type checker...",

	// Thesis
	"Consulting a paper that has no code...",
	"Reproducing results from a figure...",
	"Rewriting the related work...",
	"Renaming the variable in the equation and the code...",
	"Fitting the plot into one column...",
	"Making the caption do the heavy lifting...",
	"Arguing with a reviewer in my head...",
	"Adding an ablation nobody asked for...",
];

function pickRandom(): string {
	return messages[Math.floor(Math.random() * messages.length)]!;
}

export default function (pi: ExtensionAPI) {
	pi.on("turn_start", async (_event, ctx) => {
		ctx.ui.setWorkingMessage(pickRandom());
	});

	pi.on("turn_end", async (_event, ctx) => {
		ctx.ui.setWorkingMessage(); // Reset for next time
	});
}
