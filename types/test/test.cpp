#define BOOST_TEST_MODULE BaseTypes
#include <boost/test/unit_test.hpp>

#include <base/Angle.hpp>
#include <base/commands/Joints.hpp>
#include <base/commands/Motion2D.hpp>
#include <base/commands/Speed6D.hpp>
#include <base/Deprecated.hpp>
#include <base/Eigen.hpp>
#include <base/Float.hpp>
#include <base/JointState.hpp>
#include <base/JointLimitRange.hpp>
#include <base/JointLimits.hpp>
#include <base/JointsTrajectory.hpp>
#include <base/NamedVector.hpp>
#include <base/Point.hpp>
#include <base/Pose.hpp>
#include <base/Pressure.hpp>
//#include <base/samples/CompressedFrame.hpp>
#include <base/samples/BodyState.hpp>
#include <base/samples/BoundingBox.hpp>
#include <base/samples/DistanceImage.hpp>
#include <base/samples/Frame.hpp>
#include <base/samples/IMUSensors.hpp>
#include <base/samples/Joints.hpp>
#include <base/samples/LaserScan.hpp>
#include <base/samples/OrientedBoundingBox.hpp>
#include <base/samples/Pointcloud.hpp>
#include <base/samples/Pressure.hpp>
#include <base/samples/RigidBodyAcceleration.hpp>
#include <base/samples/RigidBodyState.hpp>
#include <base/samples/SonarBeam.hpp>
#include <base/samples/SonarScan.hpp>
#include <base/TransformWithCovariance.hpp>
#include <base/samples/Sonar.hpp>
#include <base/samples/PoseWithCovariance.hpp>
#include <base/Temperature.hpp>
#include <base/Time.hpp>
#include <base/TimeMark.hpp>
#include <base/Trajectory.hpp>
#include <base/Waypoint.hpp>
#include <base/TwistWithCovariance.hpp>

#ifdef SISL_FOUND
#include <base/Trajectory.hpp>
#endif

#include <Eigen/SVD>
#include <Eigen/LU>
#include <Eigen/Geometry>

using namespace std;

BOOST_AUTO_TEST_CASE(twist_with_covariance_validity)
{
    base::TwistWithCovariance velocity;
    BOOST_CHECK(velocity.translation() == base::Vector3d::Zero());
    BOOST_CHECK(velocity.rotation() == base::Vector3d::Zero());
    BOOST_CHECK(velocity.hasValidVelocity() == true);
    BOOST_CHECK(velocity.hasValidCovariance() == false);
    std::cout<<"TwistWithCovariance\n";
    std::cout<<velocity<<std::endl;
    velocity.setCovariance(base::Matrix6d::Identity());
    std::cout<<"TwistWithCovariance\n";
    std::cout<<velocity<<std::endl;
    BOOST_CHECK(velocity.hasValidCovariance() == true);
    velocity.invalidateVelocity();
    BOOST_CHECK(velocity.hasValidVelocity() == false);
    BOOST_CHECK(velocity.hasValidCovariance() == true);
    velocity.invalidateCovariance();
    BOOST_CHECK(velocity.hasValidVelocity() == false);
    BOOST_CHECK(velocity.hasValidCovariance() == false);
}

BOOST_AUTO_TEST_CASE(twist_with_covariance_operations)
{
    base::TwistWithCovariance vel1, vel2, vel3;
    base::Vector6d vec;
    vec<< 0.3,0.3,0.3,1.0,1.0,1.0;
    vel1.setVelocity(vec);
    vel2.setVelocity(vec);
    vel3 = vel1 * vel2;
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());
    vel3 = vel1 - vel2;
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());
    vel3 = -vel1 + vel2;
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());
    vel3 = (-vel1 / 0.5) + 2.0 * vel1;
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());

    /** Add uncertainty to the covariance **/
    vel1.cov = 0.1 * base::Matrix6d::Identity();
    vel2.cov = 0.2 * base::Matrix6d::Identity();

    vel3.invalidateCovariance();
    vel3 = -vel1 + vel2;
    BOOST_CHECK(vel3.hasValidCovariance());
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());
    std::cout<<"TwistWithCovariance add operator\n";
    std::cout<<vel3<<std::endl;

    vel3.invalidateCovariance();
    vel3 = vel1 - vel2;
    BOOST_CHECK(vel3.hasValidCovariance());
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());
    std::cout<<"TwistWithCovariance subtract operator\n";
    std::cout<<vel3<<std::endl;

    vel3.invalidateCovariance();
    vel3 = (-vel1 / 0.5) + 2.0 * vel1;
    BOOST_CHECK(vel3.hasValidCovariance());
    BOOST_CHECK(vel3.translation() == Eigen::Vector3d::Zero());
    BOOST_CHECK(vel3.rotation() == Eigen::Vector3d::Zero());

    vel3.invalidateCovariance();
    vel3 = vel1 * vel2;
    BOOST_CHECK(vel3.hasValidCovariance());
    std::cout<<"TwistWithCovariance cross product\n";
    std::cout<<vel3<<std::endl;
}

BOOST_AUTO_TEST_CASE(body_state_validity)
{
    base::samples::BodyState bs;
    bs.initUnknown();
    // check if values are valid
    BOOST_CHECK(bs.hasValidPose());
    BOOST_CHECK(!bs.hasValidPoseCovariance());
    BOOST_CHECK(bs.hasValidVelocity());
    BOOST_CHECK(!bs.hasValidVelocityCovariance());

    bs.pose.setCovariance(base::Matrix6d::Identity());
    bs.velocity.setCovariance(base::Matrix6d::Identity());
    BOOST_CHECK(bs.hasValidPoseCovariance());
    BOOST_CHECK(bs.hasValidVelocityCovariance());
    // check std::cout operator when valid uncertainty
    std::cout<<"Body State\n"<<bs<<std::endl;

    bs.invalidate();
    // check if values are not valid
    BOOST_CHECK(!bs.hasValidPose());
    BOOST_CHECK(!bs.hasValidPoseCovariance());
    BOOST_CHECK(!bs.hasValidVelocity());
    BOOST_CHECK(!bs.hasValidVelocityCovariance());

    // check std::cout operator when not valid uncertainty
    std::cout<<"Body State\n"<<bs<<std::endl;
}

BOOST_AUTO_TEST_CASE(body_state_operations)
{
    base::samples::BodyState bs1, bs2, bs3;
    bs1.initUnknown();
    bs2.initUnknown();
    bs1.pose = base::TransformWithCovariance(base::Affine3d::Identity(), 0.1 * base::Matrix6d::Identity());
    bs1.velocity = base::TwistWithCovariance(base::Vector6d::Zero(), static_cast<base::TwistWithCovariance::Covariance>(0.1 * base::TwistWithCovariance::Covariance::Identity()));
    bs2.pose = base::TransformWithCovariance(base::Affine3d(Eigen::AngleAxisd(90.0 *
                    M_PI/180.0, Eigen::Vector3d::UnitZ())), 0.2 * base::Matrix6d::Identity());
    bs2.velocity = base::TwistWithCovariance(base::Vector6d::Ones(), static_cast<base::TwistWithCovariance::Covariance>(0.2 * base::TwistWithCovariance::Covariance::Identity()));
    bs3 = bs1 * bs2;
    std::cout<<"Body State Composition\n"<<bs3<<std::endl;
    BOOST_CHECK(bs3.hasValidPose());
    BOOST_CHECK(bs3.hasValidPoseCovariance());
    BOOST_CHECK(bs3.hasValidVelocity());
    BOOST_CHECK(bs3.hasValidVelocityCovariance());

    bs3.position().setOnes();
    std::cout<<"Body State Composition\n"<<bs3<<std::endl;
    bs3.position() = bs1.position() + bs2.position();
    std::cout<<"Body State Composition\n"<<bs3<<std::endl;
    bs3.orientation() = base::Orientation::Identity();
    bs3.orientation() = bs1.orientation() * bs2.orientation();
    std::cout<<"Body State Composition\n"<<bs3<<std::endl;
}

BOOST_AUTO_TEST_CASE(joint_state)
{
    base::JointState state;
    BOOST_CHECK(state.getMode() == base::JointState::UNSET);

    // Test position field
    state.setField(base::JointState::POSITION, 0.3);
    BOOST_CHECK(state.hasPosition() == true);
    BOOST_CHECK(state.hasSpeed() == false);
    BOOST_CHECK(state.hasEffort() == false);
    BOOST_CHECK(state.hasRaw() == false);
    BOOST_CHECK(state.hasAcceleration() == false);
    BOOST_CHECK(state.isPosition() == true);
    BOOST_CHECK(state.isSpeed() == false);
    BOOST_CHECK(state.isEffort() == false);
    BOOST_CHECK(state.isRaw() == false);
    BOOST_CHECK(state.isAcceleration() == false);

    BOOST_CHECK(state.getField(base::JointState::POSITION) == 0.3);
    BOOST_CHECK(state.getMode() == base::JointState::POSITION);

    state.setField(base::JointState::POSITION, base::NaN<double>());

    // Test speed field
    state.setField(base::JointState::SPEED, -.1f);

    BOOST_CHECK(state.hasPosition() == false);
    BOOST_CHECK(state.hasSpeed() == true);
    BOOST_CHECK(state.hasEffort() == false);
    BOOST_CHECK(state.hasRaw() == false);
    BOOST_CHECK(state.hasAcceleration() == false);
    BOOST_CHECK(state.isPosition() == false);
    BOOST_CHECK(state.isSpeed() == true);
    BOOST_CHECK(state.isEffort() == false);
    BOOST_CHECK(state.isRaw() == false);
    BOOST_CHECK(state.isAcceleration() == false);

    BOOST_CHECK(state.getField(base::JointState::SPEED) == -.1f);
    BOOST_CHECK(state.getMode() == base::JointState::SPEED);

    state.setField(base::JointState::SPEED, base::NaN<float>());

    // Test effort field
    state.setField(base::JointState::EFFORT, -.5f);

    BOOST_CHECK(state.hasPosition() == false);
    BOOST_CHECK(state.hasSpeed() == false);
    BOOST_CHECK(state.hasEffort() == true);
    BOOST_CHECK(state.hasRaw() == false);
    BOOST_CHECK(state.hasAcceleration() == false);
    BOOST_CHECK(state.isPosition() == false);
    BOOST_CHECK(state.isSpeed() == false);
    BOOST_CHECK(state.isEffort() == true);
    BOOST_CHECK(state.isRaw() == false);
    BOOST_CHECK(state.isAcceleration() == false);

    BOOST_CHECK(state.getField(base::JointState::EFFORT) == -.5f);
    BOOST_CHECK(state.getMode() == base::JointState::EFFORT);

    state.setField(base::JointState::EFFORT, base::NaN<float>());

    // Test raw field
    state.setField(base::JointState::RAW, 1.5f);

    BOOST_CHECK(state.hasPosition() == false);
    BOOST_CHECK(state.hasSpeed() == false);
    BOOST_CHECK(state.hasEffort() == false);
    BOOST_CHECK(state.hasRaw() == true);
    BOOST_CHECK(state.hasAcceleration() == false);
    BOOST_CHECK(state.isPosition() == false);
    BOOST_CHECK(state.isSpeed() == false);
    BOOST_CHECK(state.isEffort() == false);
    BOOST_CHECK(state.isRaw() == true);
    BOOST_CHECK(state.isAcceleration() == false);

    BOOST_CHECK(state.getField(base::JointState::RAW) == 1.5f);
    BOOST_CHECK(state.getMode() == base::JointState::RAW);

    state.setField(base::JointState::RAW, base::NaN<float>());

    // Test acceleration field
    state.setField(base::JointState::ACCELERATION, -0.7f);

    BOOST_CHECK(state.hasPosition() == false);
    BOOST_CHECK(state.hasSpeed() == false);
    BOOST_CHECK(state.hasEffort() == false);
    BOOST_CHECK(state.hasRaw() == false);
    BOOST_CHECK(state.hasAcceleration() == true);
    BOOST_CHECK(state.isPosition() == false);
    BOOST_CHECK(state.isSpeed() == false);
    BOOST_CHECK(state.isEffort() == false);
    BOOST_CHECK(state.isRaw() == false);
    BOOST_CHECK(state.isAcceleration() == true);

    BOOST_CHECK(state.getField(base::JointState::ACCELERATION) == -0.7f);
    BOOST_CHECK(state.getMode() == base::JointState::ACCELERATION);

    // Test invalid field
    BOOST_REQUIRE_THROW(state.getField(99), std::runtime_error);
    BOOST_REQUIRE_THROW(state.setField(99, 0.5), std::runtime_error);

    //Test with multiple fields
    state.setField(base::JointState::RAW, 0.1);
    BOOST_REQUIRE_THROW(state.getMode(), std::runtime_error);
    BOOST_CHECK(state.isPosition() == false);
    BOOST_CHECK(state.isSpeed() == false);
    BOOST_CHECK(state.isEffort() == false);
    BOOST_CHECK(state.isRaw() == false);
    BOOST_CHECK(state.isAcceleration() == false);
}

BOOST_AUTO_TEST_CASE(sonar_scan)
{
    base::samples::SonarScan sonar_scan;
    base::samples::SonarBeam sonar_beam;

    sonar_scan.init(50,100,base::Angle::fromDeg(20),base::Angle::fromDeg(1));
    BOOST_CHECK(sonar_scan.data.size() == 50*100);
    BOOST_CHECK(sonar_scan.getNumberOfBytes() == 50*100);
    BOOST_CHECK(sonar_scan.getBinCount() == 50*100);
    BOOST_CHECK(sonar_scan.number_of_beams == 50);
    BOOST_CHECK(sonar_scan.number_of_bins == 100);
    BOOST_CHECK(sonar_scan.speed_of_sound == 0);
    BOOST_CHECK(sonar_scan.sampling_interval == 0);
    BOOST_CHECK(sonar_scan.angular_resolution == base::Angle::fromDeg(1));
    BOOST_CHECK(sonar_scan.start_bearing == base::Angle::fromDeg(20));
    BOOST_CHECK(sonar_scan.beamwidth_vertical == base::Angle::fromRad(0));
    BOOST_CHECK(sonar_scan.beamwidth_horizontal == base::Angle::fromRad(0));
    BOOST_CHECK(sonar_scan.time_beams.empty() == true);
    BOOST_CHECK(sonar_scan.polar_coordinates == true);

    //all should be valid because no seperate time stamp for each beam was set
    for(int i=20;i>-30;--i)
        BOOST_CHECK(sonar_scan.hasSonarBeam(base::Angle::fromDeg(i)));

    //wrong memory layout
    BOOST_REQUIRE_THROW(sonar_scan.addSonarBeam(sonar_beam),std::runtime_error);
    BOOST_REQUIRE_THROW(sonar_scan.getSonarBeam(base::Angle::fromRad(0),sonar_beam),std::runtime_error);

    sonar_beam.beam.resize(101);
    sonar_scan.toggleMemoryLayout();
    //too many bins
    BOOST_REQUIRE_THROW(sonar_scan.addSonarBeam(sonar_beam),std::runtime_error);

    sonar_beam.beam.resize(100);
    sonar_beam.bearing = base::Angle::fromDeg(25);
    //wrong bearing
    BOOST_REQUIRE_THROW(sonar_scan.addSonarBeam(sonar_beam,false),std::runtime_error);

    //add sonar beam
    sonar_beam.bearing = base::Angle::fromDeg(20);
    sonar_beam.speed_of_sound = 1500;
    sonar_beam.beamwidth_horizontal = 0.1;
    sonar_beam.beamwidth_vertical = 0.2;
    sonar_beam.sampling_interval = 0.01;
    sonar_beam.time = base::Time::now();
    for(int i=0;i<100;++i)
        sonar_beam.beam[i]=i;
    sonar_scan.addSonarBeam(sonar_beam,false);

    sonar_beam.bearing = base::Angle::fromDeg(-29);
    for(int i=0;i<100;++i)
        sonar_beam.beam[i]=23+i;
    sonar_scan.addSonarBeam(sonar_beam,false);

    BOOST_CHECK(sonar_scan.hasSonarBeam(base::Angle::fromDeg(20)));
    for(int i=19;i>-29;--i)
        BOOST_CHECK(!sonar_scan.hasSonarBeam(base::Angle::fromDeg(i)));
    BOOST_CHECK(sonar_scan.hasSonarBeam(base::Angle::fromDeg(-29)));

    base::samples::SonarBeam temp_beam;
    BOOST_CHECK_THROW(sonar_scan.getSonarBeam(base::Angle::fromDeg(21),temp_beam),std::runtime_error);
    sonar_scan.getSonarBeam(base::Angle::fromDeg(-29),temp_beam);

    BOOST_CHECK_SMALL(temp_beam.bearing.rad-sonar_beam.bearing.rad,0.0001);
    BOOST_CHECK(temp_beam.speed_of_sound == sonar_beam.speed_of_sound);
    BOOST_CHECK(temp_beam.beamwidth_horizontal == sonar_beam.beamwidth_horizontal);
    BOOST_CHECK(temp_beam.beamwidth_vertical == sonar_beam.beamwidth_vertical);
    BOOST_CHECK(temp_beam.sampling_interval == sonar_beam.sampling_interval);
    BOOST_CHECK(temp_beam.time == sonar_beam.time);
    BOOST_CHECK(temp_beam.beam == sonar_beam.beam);

    //toggleMemoryLayout
    sonar_scan.toggleMemoryLayout();
    for(int i=0;i<sonar_scan.number_of_bins;++i)
        BOOST_CHECK(sonar_scan.data[i*sonar_scan.number_of_beams] == i);
    for(int i=0;i<sonar_scan.number_of_bins;++i)
        BOOST_CHECK(sonar_scan.data[sonar_scan.number_of_beams-1+i*sonar_scan.number_of_beams] == i+23);

    sonar_scan.toggleMemoryLayout();
    sonar_scan.getSonarBeam(base::Angle::fromDeg(-29),temp_beam);
    BOOST_CHECK(temp_beam.speed_of_sound == sonar_beam.speed_of_sound);
    BOOST_CHECK(temp_beam.beamwidth_horizontal == sonar_beam.beamwidth_horizontal);
    BOOST_CHECK(temp_beam.beamwidth_vertical == sonar_beam.beamwidth_vertical);
    BOOST_CHECK(temp_beam.sampling_interval == sonar_beam.sampling_interval);
    BOOST_CHECK(temp_beam.time == sonar_beam.time);
    BOOST_CHECK(temp_beam.beam == sonar_beam.beam);
}

BOOST_AUTO_TEST_CASE( time_test )
{
    std::cout << base::Time::fromSeconds( 35.553 ) << std::endl;
    std::cout << base::Time::fromSeconds( -5.553 ) << std::endl;

    base::Time null_time;
    null_time.fromMicroseconds(0);
    BOOST_CHECK(null_time.isNull());
    null_time.fromMilliseconds(0);
    BOOST_CHECK(null_time.isNull());


    base::Time max_time;
    max_time = base::Time::fromMicroseconds(std::numeric_limits<int64_t>::max());
    BOOST_REQUIRE_EQUAL(max_time.toMicroseconds(), std::numeric_limits<int64_t>::max());
    BOOST_REQUIRE_EQUAL(max_time, base::Time::max());
}

BOOST_AUTO_TEST_CASE( laser_scan_test )
{
    //configure laser scan
    base::samples::LaserScan laser_scan;
    laser_scan.start_angle = M_PI*0.25;
    laser_scan.angular_resolution = M_PI*0.01;
    laser_scan.speed = 330;
    laser_scan.minRange = 1000;
    laser_scan.maxRange = 20000;

    //add some points
    laser_scan.ranges.push_back(1000);
    laser_scan.ranges.push_back(1000);
    laser_scan.ranges.push_back(2000);
    laser_scan.ranges.push_back(999);
    laser_scan.ranges.push_back(2000);

    Eigen::Affine3d trans;
    trans.setIdentity();
    trans.translation() = Eigen::Vector3d(-1.0,0.0,0.0);
    std::vector<Eigen::Vector3d> points;
    laser_scan.convertScanToPointCloud(points,trans,false);

    //check translation
    BOOST_CHECK(points.size() == 5);
    BOOST_CHECK(abs(points[0].x()-( -1+cos(M_PI*0.25))) < 0.000001);
    BOOST_CHECK(abs(points[0].y()-( sin(M_PI*0.25))) < 0.000001);
    BOOST_CHECK(points[0].z() == 0);
    BOOST_CHECK(abs(points[1].x()-( -1+cos(M_PI*0.25+laser_scan.angular_resolution))) < 0.000001);
    BOOST_CHECK(abs(points[1].y()-( sin(M_PI*0.25+laser_scan.angular_resolution))) < 0.000001);
    BOOST_CHECK(abs(points[2].x()-( -1+2.0*cos(M_PI*0.25+laser_scan.angular_resolution*2))) < 0.000001);
    BOOST_CHECK(abs(points[2].y()-( 2.0*sin(M_PI*0.25+laser_scan.angular_resolution*2))) < 0.000001);
    BOOST_CHECK(std::isnan(points[3].x()));
    BOOST_CHECK(std::isnan(points[3].y()));
    BOOST_CHECK(std::isnan(points[3].z()));

    //check rotation and translation
    trans.setIdentity();
    trans.translation() = Eigen::Vector3d(-1.0,0.0,0.0);
    trans.rotate(Eigen::AngleAxisd(0.1*M_PI,Eigen::Vector3d::UnitZ()));
    laser_scan.convertScanToPointCloud(points,trans,false);
    BOOST_CHECK(points.size() == 5);
    double x = cos(M_PI*0.25);
    double y = sin(M_PI*0.25);
    BOOST_CHECK(abs(points[0].x()-(-1+x*cos(0.1*M_PI)-y*sin(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(abs(points[0].y()-(x*sin(0.1*M_PI)+y*cos(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(points[0].z() == 0);
    x = cos(M_PI*0.25+laser_scan.angular_resolution);
    y = sin(M_PI*0.25+laser_scan.angular_resolution);
    BOOST_CHECK(abs(points[1].x()-(-1+x*cos(0.1*M_PI)-y*sin(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(abs(points[1].y()-(x*sin(0.1*M_PI)+y*cos(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(std::isnan(points[3].x()));
    BOOST_CHECK(std::isnan(points[3].y()));
    BOOST_CHECK(std::isnan(points[3].z()));

    //check skipping of invalid scan points
    laser_scan.convertScanToPointCloud(points,trans);
    BOOST_CHECK(points.size() == 4);
    x = cos(M_PI*0.25);
    y = sin(M_PI*0.25);
    BOOST_CHECK(abs(points[0].x()-(-1+x*cos(0.1*M_PI)-y*sin(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(abs(points[0].y()-(x*sin(0.1*M_PI)+y*cos(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(points[0].z() == 0);
    x = cos(M_PI*0.25+laser_scan.angular_resolution);
    y = sin(M_PI*0.25+laser_scan.angular_resolution);
    BOOST_CHECK(abs(points[1].x()-(-1+x*cos(0.1*M_PI)-y*sin(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(abs(points[1].y()-(x*sin(0.1*M_PI)+y*cos(0.1*M_PI))) < 0.0000001);
    BOOST_CHECK(!std::isnan(points[3].x()));
    BOOST_CHECK(!std::isnan(points[3].y()));
    BOOST_CHECK(!std::isnan(points[3].z()));
}

BOOST_AUTO_TEST_CASE(distance_image_test)
{
    /** Distance image **/
    base::samples::DistanceImage dimage(2,2);
    dimage.setIntrinsic(1, 1, 1, 1);
    dimage.data.push_back(1.0); // 1st value
    dimage.data.push_back(2.0); // 2nd value
    dimage.data.push_back(2.0); // 3rd value
    dimage.data.push_back(1.0); //4th value

    /** Point cloud **/
    base::samples::Pointcloud point_cloud = dimage.getPointCloud();
    BOOST_CHECK(point_cloud.points.size() == dimage.data.size());

    BOOST_CHECK(point_cloud.points[0] == Eigen::Vector3d(-1.0, -1.00, 1.00));
    BOOST_CHECK(point_cloud.points[1] == Eigen::Vector3d(0.0, -2.00, 2.00));
    BOOST_CHECK(point_cloud.points[2] == Eigen::Vector3d(-2.0, 0.00, 2.00));
    BOOST_CHECK(point_cloud.points[3] == Eigen::Vector3d(0.0, 0.00, 1.00));

    /** Scene and image point projections **/
    dimage.setSize(3,2);
    dimage.clear();
    dimage.data[0] = 1.0;
    dimage.data[1] = 2.0;
    dimage.data[2] = 0.0;
    dimage.data[3] = std::numeric_limits<base::samples::DistanceImage::scalar>::denorm_min();
    dimage.data[4] = std::numeric_limits<base::samples::DistanceImage::scalar>::infinity();
    dimage.data[5] = std::numeric_limits<base::samples::DistanceImage::scalar>::quiet_NaN();

    Eigen::Vector3d scene_point = Eigen::Vector3d::Zero();
    size_t x = std::numeric_limits<size_t>::max(), y = std::numeric_limits<size_t>::max();
    // test valid projections
    BOOST_CHECK(dimage.getScenePoint(0,0,scene_point));
    BOOST_CHECK(dimage.getImagePoint(scene_point,x,y));
    BOOST_CHECK(x == 0);
    BOOST_CHECK(y == 0);

    BOOST_CHECK(dimage.getScenePoint(1,0,scene_point));
    BOOST_CHECK(dimage.getImagePoint(scene_point,x,y));
    BOOST_CHECK(x == 1);
    BOOST_CHECK(y == 0);

    // test invalid distacnes
    scene_point.setZero();
    x = std::numeric_limits<size_t>::max();
    y = std::numeric_limits<size_t>::max();
    BOOST_CHECK(dimage.getScenePoint(2,0,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    BOOST_CHECK(dimage.getScenePoint(0,1,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    BOOST_CHECK(dimage.getScenePoint(1,1,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    BOOST_CHECK(dimage.getScenePoint(2,1,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    BOOST_CHECK(dimage.getImagePoint(scene_point,x,y) == false);
    BOOST_CHECK(x == std::numeric_limits<size_t>::max());
    BOOST_CHECK(y == std::numeric_limits<size_t>::max());

    // test bounds
    BOOST_CHECK(dimage.getScenePoint(3,2,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    BOOST_CHECK(dimage.getScenePoint(0,2,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    BOOST_CHECK(dimage.getScenePoint(3,0,scene_point) == false);
    BOOST_CHECK(scene_point == Eigen::Vector3d::Zero());
    scene_point = Eigen::Vector3d(1.0, 1.0, 1.0);
    BOOST_CHECK(dimage.getImagePoint(scene_point,x,y) == false);
    BOOST_CHECK(x == std::numeric_limits<size_t>::max());
    BOOST_CHECK(y == std::numeric_limits<size_t>::max());
}

BOOST_AUTO_TEST_CASE( pose_test )
{
    Eigen::Vector3d pos( 10, -1, 20.5 );
    Eigen::Quaterniond orientation( Eigen::AngleAxisd( 0.2, Eigen::Vector3d(0.5, 1.4, 0.1) ) );

    base::Pose p( pos, orientation );
    Eigen::Affine3d t( p.toTransform() );

    BOOST_CHECK( pos.isApprox( t.translation() ) );
    BOOST_CHECK( orientation.isApprox( Eigen::Quaterniond(t.rotation()), 0.01 ) );

    cout << Eigen::Quaterniond(t.rotation()).coeffs().transpose() << endl;
    cout << orientation.coeffs().transpose() << endl;
}

BOOST_AUTO_TEST_CASE( rbs_to_transform )
{
    // test casting operator from rigid body state to eigen::Transform
    base::samples::RigidBodyState rbs;

    Eigen::Affine3d r1( rbs );
    base::Affine3d r2( rbs );
}

base::Angle rand_angle()
{
    return base::Angle::fromRad(((rand() / (RAND_MAX + 1.0))-0.5) * M_PI);
}

BOOST_AUTO_TEST_CASE( yaw_test )
{
    using namespace base;

    for(int i=0;i<10;i++)
    {
	Angle roll = rand_angle();
	Angle pitch = rand_angle();
	Angle yaw = rand_angle();
	Eigen::Quaterniond pitchroll =
	    Eigen::AngleAxisd( pitch.getRad(), Eigen::Vector3d::UnitY() ) *
	    Eigen::AngleAxisd( roll.getRad(), Eigen::Vector3d::UnitX() );

	Eigen::Quaterniond rot =
	    Eigen::AngleAxisd( yaw.getRad(), Eigen::Vector3d::UnitZ() ) *
	    pitchroll;

	BOOST_CHECK_CLOSE( yaw.getRad(), Angle::fromRad(getYaw( rot )).getRad(), 1e-3 );

	rot = base::removeYaw( rot );
	BOOST_CHECK( rot.isApprox( pitchroll ) );
    }
}

BOOST_AUTO_TEST_CASE( angle_segment )
{
    using base::Angle;
    using base::AngleSegment;

    {
        Angle start = Angle::fromRad(-M_PI);
        AngleSegment test(start, 2*M_PI);
        for(int i = 0; i < 20; i++)
        {
            Angle angle = Angle::fromRad(i*2*M_PI/20 - M_PI);
            BOOST_CHECK(test.isInside(angle));
        }

    }

    {
        Angle start = Angle::fromRad(-M_PI / 2.0);
        AngleSegment test(start, M_PI);
        {
        Angle angle = Angle::fromRad(0);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(-M_PI / 2.0);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(M_PI / 2.0);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(M_PI / 3 * 4);
        BOOST_CHECK(!test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(-M_PI / 3 * 4);
        BOOST_CHECK(!test.isInside(angle));
        }

    }
    {
        Angle start = Angle::fromRad(M_PI / 2.0);
        AngleSegment test(start, M_PI);
        {
        Angle angle = Angle::fromRad(0);
        BOOST_CHECK(!test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(-M_PI / 2.0);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(M_PI / 2.0);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(M_PI / 3 * 4);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(M_PI / 1 * 4);
        BOOST_CHECK(!test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(-M_PI / 3 * 4);
        BOOST_CHECK(test.isInside(angle));
        }
        {
        Angle angle = Angle::fromRad(-M_PI / 1 * 4);
        BOOST_CHECK(!test.isInside(angle));
        }

    }

}

#include <base/Float.hpp>

BOOST_AUTO_TEST_CASE( test_inf_nan )
{
    {
        float inf = base::infinity<float>();
        BOOST_REQUIRE( base::isInfinity(inf) );
        BOOST_REQUIRE( base::isInfinity(inf * 10) );
        BOOST_REQUIRE(inf == inf);
    }

    {
        double inf = base::infinity<double>();
        BOOST_REQUIRE( base::isInfinity(inf) );
        BOOST_REQUIRE( base::isInfinity(inf * 10) );
        BOOST_REQUIRE(inf == inf);
    }

    {
        float nan = base::unset<float>();
        BOOST_REQUIRE( base::isUnset(nan) );
        BOOST_REQUIRE( base::isUnset(nan * 10) );
        BOOST_REQUIRE(nan != nan);
    }

    {
        double nan = base::unset<double>();
        BOOST_REQUIRE( base::isUnset(nan) );
        BOOST_REQUIRE( base::isUnset(nan * 10) );
        BOOST_REQUIRE(nan != nan);
    }

    {
        float nan = base::unknown<float>();
        BOOST_REQUIRE( base::isUnknown(nan) );
        BOOST_REQUIRE( base::isUnknown(nan * 10) );
        BOOST_REQUIRE(nan != nan);
    }

    {
        double nan = base::unknown<double>();
        BOOST_REQUIRE( base::isUnknown(nan) );
        BOOST_REQUIRE( base::isUnknown(nan * 10) );
        BOOST_REQUIRE(nan != nan);
    }
}


BOOST_AUTO_TEST_CASE( frame_test )
{
    using namespace base::samples::frame;

    Frame frame;
    frame.init(200,300,8,MODE_GRAYSCALE);
    BOOST_CHECK(frame.getNumberOfBytes() == 200*300*1);
    BOOST_CHECK(frame.getPixelSize() == 1);
    BOOST_CHECK(frame.getPixelCount() == 200*300);
    BOOST_CHECK(frame.getChannelCount() == 1);
    BOOST_CHECK(frame.isCompressed() == false);
    BOOST_CHECK(frame.getHeight() == 300);
    BOOST_CHECK(frame.getWidth() == 200);

    frame.init(200,300,9,MODE_GRAYSCALE);
    BOOST_CHECK(frame.getNumberOfBytes() == 200*300*2);
    BOOST_CHECK(frame.getPixelSize() == 2);
    BOOST_CHECK(frame.getPixelCount() == 200*300);
    BOOST_CHECK(frame.getChannelCount() == 1);
    BOOST_CHECK(frame.isCompressed() == false);
    BOOST_CHECK(frame.getHeight() == 300);
    BOOST_CHECK(frame.getWidth() == 200);

    frame.init(200,300,8,MODE_RGB);
    BOOST_CHECK(frame.getNumberOfBytes() == 200*300*3);
    BOOST_CHECK(frame.getPixelSize() == 3);
    BOOST_CHECK(frame.getPixelCount() == 200*300);
    BOOST_CHECK(frame.getChannelCount() == 3);
    BOOST_CHECK(frame.isCompressed() == false);
    BOOST_CHECK(frame.getHeight() == 300);
    BOOST_CHECK(frame.getWidth() == 200);

    frame.init(200,300,8,MODE_GRAYSCALE,-1,200*300*1);
    BOOST_CHECK(frame.getNumberOfBytes() == 200*300*1);
    BOOST_CHECK(frame.getPixelSize() == 1);
    BOOST_CHECK(frame.getPixelCount() == 200*300);
    BOOST_CHECK(frame.getChannelCount() == 1);
    BOOST_CHECK(frame.isCompressed() == false);
    BOOST_CHECK(frame.getHeight() == 300);
    BOOST_CHECK(frame.getWidth() == 200);

    frame.init(200,300,8,MODE_PJPG,-1,0.5*200*300);
    BOOST_CHECK(frame.getNumberOfBytes() == 0.5*200*300);
    BOOST_CHECK(frame.getPixelSize() == 1);
    BOOST_CHECK(frame.getPixelCount() == 200*300);
    BOOST_CHECK(frame.getChannelCount() == 1);
    BOOST_CHECK(frame.isCompressed() == true);
    BOOST_CHECK(frame.getHeight() == 300);
    BOOST_CHECK(frame.getWidth() == 200);

    BOOST_CHECK_THROW(frame.init(200,300,8,MODE_RGB,-1,0.5*200*300),std::runtime_error);

    frame.init(200,300,8,MODE_GRAYSCALE);
    Frame frame2(frame);
    BOOST_CHECK(frame2.getNumberOfBytes() == 200*300);
    BOOST_CHECK(frame2.getPixelSize() == 1);
    BOOST_CHECK(frame2.getPixelCount() == 200*300);
    BOOST_CHECK(frame2.getChannelCount() == 1);
    BOOST_CHECK(frame2.isCompressed() == false);
    BOOST_CHECK(frame2.getHeight() == 300);
    BOOST_CHECK(frame2.getWidth() == 200);
}

BOOST_AUTO_TEST_CASE( rbs_validity )
{
    base::samples::RigidBodyState rbs;
    rbs.initUnknown();
    // check if values are unknown
    BOOST_CHECK(!rbs.isKnownValue(rbs.cov_position));
    BOOST_CHECK(!rbs.isKnownValue(rbs.cov_velocity));
    BOOST_CHECK(!rbs.isKnownValue(rbs.cov_orientation));
    BOOST_CHECK(!rbs.isKnownValue(rbs.cov_angular_velocity));
    BOOST_CHECK(rbs.position == Eigen::Vector3d::Zero());
    BOOST_CHECK(rbs.velocity == Eigen::Vector3d::Zero());
    BOOST_CHECK(rbs.angular_velocity == Eigen::Vector3d::Zero());
    BOOST_CHECK(rbs.orientation.x() == 0 && rbs.orientation.y() == 0 &&
                rbs.orientation.z() == 0 && rbs.orientation.w() == 1);

    // check if values are valid
    BOOST_CHECK(rbs.hasValidPosition());
    BOOST_CHECK(rbs.hasValidPositionCovariance());
    BOOST_CHECK(rbs.hasValidOrientation());
    BOOST_CHECK(rbs.hasValidOrientationCovariance());
    BOOST_CHECK(rbs.hasValidVelocity());
    BOOST_CHECK(rbs.hasValidVelocityCovariance());
    BOOST_CHECK(rbs.hasValidAngularVelocity());
    BOOST_CHECK(rbs.hasValidAngularVelocityCovariance());

    rbs.invalidate();
    // check if values are invalid
    BOOST_CHECK(!rbs.hasValidPosition());
    BOOST_CHECK(!rbs.hasValidPositionCovariance());
    BOOST_CHECK(!rbs.hasValidOrientation());
    BOOST_CHECK(!rbs.hasValidOrientationCovariance());
    BOOST_CHECK(!rbs.hasValidVelocity());
    BOOST_CHECK(!rbs.hasValidVelocityCovariance());
    BOOST_CHECK(!rbs.hasValidAngularVelocity());
    BOOST_CHECK(!rbs.hasValidAngularVelocityCovariance());
}

BOOST_AUTO_TEST_CASE( transform_with_covariance )
{
    // test if the relative transform also
    // takes the uncertainty into account
    base::Matrix6d lt1;
    lt1 <<
	0.1, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, -3.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, -2.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, -1.0;

    base::TransformWithCovariance t1(
	    Eigen::Affine3d(Eigen::Translation3d(Eigen::Vector3d(1,0,0)) * Eigen::AngleAxisd( M_PI/2.0, Eigen::Vector3d::UnitX()) ),
	    lt1 );

    base::Matrix6d lt2;
    lt2 <<
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.2, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 2.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 3.0;

    base::TransformWithCovariance t2(
	    Eigen::Affine3d(Eigen::Translation3d(Eigen::Vector3d(0,1,2)) * Eigen::AngleAxisd( M_PI/2.0, Eigen::Vector3d::UnitY()) ),
	    lt2 );

    // chain a transform with uncertainty
    base::TransformWithCovariance tr = t2 * t1;

    // and recover the second transform
    base::TransformWithCovariance t2r = tr.compositionInv( t1 );
    base::TransformWithCovariance t1r = tr.preCompositionInv( t2 );

    const double sigma = 1e-12;

    BOOST_CHECK( t2.getTransform().matrix().isApprox( t2r.getTransform().matrix(), sigma ) );
    BOOST_CHECK( t2.getCovariance().isApprox( t2r.getCovariance(), sigma ) );

    BOOST_CHECK( t1.getTransform().matrix().isApprox( t1r.getTransform().matrix(), sigma ) );
    BOOST_CHECK( t1.getCovariance().isApprox( t1r.getCovariance(), sigma ) );
}

BOOST_AUTO_TEST_CASE( pose_with_covariance )
{
    base::samples::RigidBodyState rbs;
    rbs.time = base::Time::fromSeconds(1000);
    rbs.sourceFrame = "laser";
    rbs.targetFrame = "body";
    rbs.position = base::Vector3d(1,2,3);
    rbs.cov_position = 0.1 * base::Matrix3d::Identity();
    rbs.orientation = Eigen::AngleAxisd(0.5*M_PI,Eigen::Vector3d::UnitZ()) *
                        Eigen::AngleAxisd(-0.2*M_PI,Eigen::Vector3d::UnitY()) *
                        Eigen::AngleAxisd(0.1*M_PI,Eigen::Vector3d::UnitX());
    rbs.cov_orientation = 0.02 * base::Matrix3d::Identity();

    base::samples::PoseWithCovariance t(rbs);
    BOOST_CHECK(rbs.time == t.time);
    BOOST_CHECK(rbs.sourceFrame == t.object_frame_id);
    BOOST_CHECK(rbs.targetFrame == t.frame_id);
    BOOST_CHECK(rbs.position.isApprox(t.transform.translation, 1e-12));
    BOOST_CHECK(rbs.cov_position.isApprox(t.transform.getTranslationCov(), 1e-12));
    BOOST_CHECK(rbs.orientation.isApprox(t.transform.orientation, 1e-12));
    BOOST_CHECK(rbs.cov_orientation.isApprox(t.transform.getOrientationCov(), 1e-12));

    base::samples::RigidBodyState rbs2 = t.toRigidBodyState();
    BOOST_CHECK(rbs.time == rbs2.time);
    BOOST_CHECK(rbs.sourceFrame == rbs2.sourceFrame);
    BOOST_CHECK(rbs.targetFrame == rbs2.targetFrame);
    BOOST_CHECK(rbs.position.isApprox(rbs2.position, 1e-12));
    BOOST_CHECK(rbs.cov_position.isApprox(rbs2.cov_position, 1e-12));
    BOOST_CHECK(rbs.orientation.isApprox(rbs2.orientation, 1e-12));
    BOOST_CHECK(rbs.cov_orientation.isApprox(rbs2.cov_orientation, 1e-12));

    // test operator*
    base::Matrix6d lt1;
    lt1 <<
        0.1, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, -3.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, -2.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, -1.0;
    base::samples::PoseWithCovariance body_in_world(base::TransformWithCovariance(
            Eigen::Affine3d(Eigen::Translation3d(Eigen::Vector3d(1,0,0)) * Eigen::AngleAxisd( M_PI/2.0, Eigen::Vector3d::UnitX()) ),
            lt1 ));
    body_in_world.time = base::Time();

    base::Matrix6d lt2;
    lt2 <<
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.2, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 2.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 3.0;
    base::samples::PoseWithCovariance sensor_in_body(base::TransformWithCovariance(
            Eigen::Affine3d(Eigen::Translation3d(Eigen::Vector3d(0,1,2)) * Eigen::AngleAxisd( M_PI/2.0, Eigen::Vector3d::UnitY()) ),
            lt2 ));
    sensor_in_body.time = base::Time::now();

    body_in_world.frame_id = "world";
    body_in_world.object_frame_id = "body";
    sensor_in_body.object_frame_id = "sensor";
    sensor_in_body.frame_id = "body";
    base::samples::PoseWithCovariance sensor_in_world = body_in_world * sensor_in_body;

    // check composition
    BOOST_CHECK(sensor_in_world.object_frame_id == sensor_in_body.object_frame_id);
    BOOST_CHECK(sensor_in_world.frame_id == body_in_world.frame_id);
    BOOST_CHECK(sensor_in_world.time == sensor_in_body.time);

    base::samples::PoseWithCovariance body_in_world_r(sensor_in_world.transform.compositionInv(sensor_in_body.transform));
    base::samples::PoseWithCovariance sensor_in_body_r(sensor_in_world.transform.preCompositionInv(body_in_world.transform));

    BOOST_CHECK( body_in_world.getTransform().matrix().isApprox( body_in_world_r.getTransform().matrix(), 1e-12 ) );
    BOOST_CHECK( body_in_world.getCovariance().isApprox( body_in_world_r.getCovariance(), 1e-12 ) );

    BOOST_CHECK( sensor_in_body.getTransform().matrix().isApprox( sensor_in_body_r.getTransform().matrix(), 1e-12 ) );
    BOOST_CHECK( sensor_in_body.getCovariance().isApprox( sensor_in_body_r.getCovariance(), 1e-12 ) );
}

BOOST_AUTO_TEST_CASE( bounding_box )
{
    base::samples::BoundingBox bb;

    BOOST_CHECK(bb.hasValidBoundingBox() == false);
    BOOST_CHECK(bb.hasValidCovariance() == false);

    bb = base::samples::BoundingBox(base::Time::now(),
                                    base::Vector3d(0, 0, 0));

    BOOST_CHECK(bb.hasValidBoundingBox() == false);
    BOOST_CHECK(bb.hasValidPosition() == true);
    BOOST_CHECK(bb.hasValidDimension() == false);

    bb = base::samples::BoundingBox(base::Time::now(),
                                    base::Vector3d(0, 0, 0),
                                    base::Vector3d(0, 0, 0));

    BOOST_CHECK(bb.hasValidBoundingBox() == true);
    BOOST_CHECK(bb.hasValidPosition() == true);
    BOOST_CHECK(bb.hasValidDimension() == true);

    bb.cov_position = base::Matrix3d::Zero();

    BOOST_CHECK(bb.hasValidCovariance() == false);
    BOOST_CHECK(bb.hasValidCovPosition() == true);
    BOOST_CHECK(bb.hasValidCovDimension() == false);

    bb.cov_dimension = base::Matrix3d::Zero();

    BOOST_CHECK(bb.hasValidCovariance() == true);
    BOOST_CHECK(bb.hasValidCovPosition() == true);
    BOOST_CHECK(bb.hasValidCovDimension() == true);
}

BOOST_AUTO_TEST_CASE( oriented_bounding_box )
{
    base::samples::OrientedBoundingBox obb;
    BOOST_CHECK(obb.hasValidBoundingBox() == false);
    BOOST_CHECK(obb.hasValidCovariance() == false);
    BOOST_CHECK(obb.hasValidOrientation() == false);

    obb = base::samples::OrientedBoundingBox(base::Time::now(),
                                             base::Vector3d(0, 0, 0));

    BOOST_CHECK(obb.hasValidBoundingBox() == false);
    BOOST_CHECK(obb.hasValidPosition() == true);
    BOOST_CHECK(obb.hasValidDimension() == false);
    BOOST_CHECK(obb.hasValidOrientation() == false);

    obb = base::samples::OrientedBoundingBox(base::Time::now(),
                                             base::Vector3d(0, 0, 0),
                                             base::Vector3d(0, 0, 0));

    BOOST_CHECK(obb.hasValidBoundingBox() == false);
    BOOST_CHECK(obb.hasValidPosition() == true);
    BOOST_CHECK(obb.hasValidDimension() == true);
    BOOST_CHECK(obb.hasValidOrientation() == false);

    obb = base::samples::OrientedBoundingBox(base::Time::now(),
                                             base::Vector3d(0, 0, 0),
                                             base::Vector3d(0, 0, 0),
                                             base::Orientation(0, 0, 0, 0));

    BOOST_CHECK(obb.hasValidBoundingBox() == true);
    BOOST_CHECK(obb.hasValidPosition() == true);
    BOOST_CHECK(obb.hasValidDimension() == true);
    BOOST_CHECK(obb.hasValidOrientation() == true);

    obb = base::samples::OrientedBoundingBox(base::Time::now(),
                                             base::Vector3d(1, 1, 1),
                                             base::Vector3d(1, 1, 1),
                                             base::Quaterniond::Identity());


    BOOST_CHECK(obb.position == base::Vector3d(1, 1, 1));
    BOOST_CHECK(obb.dimension == base::Vector3d(1, 1, 1));
    BOOST_CHECK(obb.orientation.w() == 1);
    BOOST_CHECK(obb.orientation.vec() == base::Vector3d(0, 0, 0));

    BOOST_CHECK(obb.hasValidCovariance() == false);
    BOOST_CHECK(obb.hasValidCovPosition() == false);
    BOOST_CHECK(obb.hasValidCovDimension() == false);
    BOOST_CHECK(obb.hasValidCovOrientation() == false);

    obb.cov_position = base::Matrix3d::Zero();

    BOOST_CHECK(obb.hasValidCovariance() == false);
    BOOST_CHECK(obb.hasValidCovPosition() == true);
    BOOST_CHECK(obb.hasValidCovDimension() == false);
    BOOST_CHECK(obb.hasValidCovOrientation() == false);

    obb.cov_dimension = base::Matrix3d::Zero();

    BOOST_CHECK(obb.hasValidCovariance() == false);
    BOOST_CHECK(obb.hasValidCovPosition() == true);
    BOOST_CHECK(obb.hasValidCovDimension() == true);
    BOOST_CHECK(obb.hasValidCovOrientation() == false);

    obb.cov_orientation = base::Matrix3d::Zero();

    BOOST_CHECK(obb.hasValidCovariance() == true);
    BOOST_CHECK(obb.hasValidCovPosition() == true);
    BOOST_CHECK(obb.hasValidCovDimension() == true);
    BOOST_CHECK(obb.hasValidCovOrientation() == true);
}

BOOST_AUTO_TEST_CASE( waypoint )
{
    base::Waypoint wp;
    BOOST_CHECK(wp.hasValidPosition() == true);
    BOOST_CHECK(wp.position == base::Vector3d(1, 0, 0));
    BOOST_CHECK(wp.heading == 0);
    BOOST_CHECK(wp.tol_position == 0);
    BOOST_CHECK(wp.tol_heading == 0);

    wp = base::Waypoint(base::Vector3d(1, 1, 1), M_PI);
    BOOST_CHECK(wp.hasValidPosition() == true);
    BOOST_CHECK(wp.position == base::Vector3d(1, 1, 1));
    BOOST_CHECK(wp.heading == M_PI);
    BOOST_CHECK(wp.tol_position == 0);
    BOOST_CHECK(wp.tol_heading == 0);

    wp = base::Waypoint(base::Vector3d(1, 1, 1), M_PI_2, 1, 2);
    BOOST_CHECK(wp.position == base::Vector3d(1, 1, 1));
    BOOST_CHECK(wp.hasValidPosition() == true);
    BOOST_CHECK(wp.heading == M_PI_2);
    BOOST_CHECK(wp.tol_position == 1);
    BOOST_CHECK(wp.tol_heading == 2);

    wp = base::unknown<base::Waypoint>();
    BOOST_CHECK(wp.hasValidPosition() == false);
    BOOST_CHECK(base::isUnknown(wp.heading) == true);
    BOOST_CHECK(base::isUnknown(wp.tol_position) == true);
    BOOST_CHECK(base::isUnknown(wp.tol_heading) == true);
}

BOOST_AUTO_TEST_CASE(euler_rate_operations)
{
    // Expected result of the mapping
    base::Vector3d expect;

    // Input Euler rate vector as (vyaw, vpitch, vroll)
    base::Vector3d euler_rate = base::Vector3d::Random();

    // Input body angular velocity vector as (wx, wy, wz)
    base::Vector3d ang_vel = base::Vector3d::Random();

    // For roll = pitch = 0, the mappings are the identity, except that the vector order
    // is reversed.
    base::Orientation yaw_only = Eigen::AngleAxisd(M_PI, Eigen::Vector3d::UnitZ()) *
                                 base::Orientation::Identity();

    // Naturally, this is valid for both direct and inverse mappings
    BOOST_CHECK(euler_rate.reverse().isApprox(
                base::eulerRate2AngularVelocity(euler_rate, yaw_only), 1e-6));
    BOOST_CHECK(ang_vel.reverse().isApprox(
                base::angularVelocity2EulerRate(ang_vel, yaw_only), 1e-6));

    // The yaw value does not affect the mappings
    base::Orientation pr = Eigen::AngleAxisd(M_PI / 3, Eigen::Vector3d::UnitY()) *
                           Eigen::AngleAxisd(M_PI / 6, Eigen::Vector3d::UnitX());

    base::Orientation ypr1 = Eigen::AngleAxisd(M_PI_2, Eigen::Vector3d::UnitZ()) * pr;
    base::Orientation ypr2 = Eigen::AngleAxisd(0, Eigen::Vector3d::UnitZ()) * pr;
    base::Orientation ypr3 = Eigen::AngleAxisd(-M_PI_2, Eigen::Vector3d::UnitZ()) * pr;

    // Naturally, this is valid for both direct and inverse mappings
    BOOST_CHECK(base::eulerRate2AngularVelocity(euler_rate, ypr1).isApprox(
                base::eulerRate2AngularVelocity(euler_rate, ypr2), 1e-6));
    BOOST_CHECK(base::eulerRate2AngularVelocity(euler_rate, ypr2).isApprox(
                base::eulerRate2AngularVelocity(euler_rate, ypr3), 1e-6));

    BOOST_CHECK(base::angularVelocity2EulerRate(ang_vel, ypr1).isApprox(
                base::angularVelocity2EulerRate(ang_vel, ypr2), 1e-6));
    BOOST_CHECK(base::angularVelocity2EulerRate(ang_vel, ypr2).isApprox(
                base::angularVelocity2EulerRate(ang_vel, ypr3), 1e-6));

    // Validates known-results from euler-rate (vyaw, vpitch, vroll) to (wx, wy, wz)
    euler_rate = base::Vector3d(1, 1, 1);
    expect = base::Vector3d(0.1339746, 1.1160254, -0.0669873);
    BOOST_CHECK(expect.isApprox(base::eulerRate2AngularVelocity(euler_rate, ypr1), 1e-6));

    // Validates known-results from angular velocity (wx, wy, wz) to (vyaw, vpitch, vroll)
    ang_vel = base::Vector3d(1, 1, 1);
    expect = base::Vector3d(2.7320508, 0.3660254, 3.3660254);
    BOOST_CHECK(expect.isApprox(base::angularVelocity2EulerRate(euler_rate, ypr1), 1e-6));
}

#ifdef SISL_FOUND
#include <base/geometry/spline.h>
BOOST_AUTO_TEST_CASE( spline_to_points )
{
    std::vector<base::Vector3d> pointsIn;

    for(int i = 0; i < 10; i++)
        pointsIn.push_back(base::Vector3d(i, i, 0));

    base::geometry::Spline3 spline;
    spline.interpolate(pointsIn);

    std::vector<base::Vector3d> pointsOut = spline.sample(0.1);
    for(std::vector<base::Vector3d>::iterator it = pointsOut.begin(); it != pointsOut.end(); it++)
    {
        BOOST_CHECK(fabs(it->x() - it->y()) < 0.001);
    }

    BOOST_CHECK(pointsOut.begin()->x() == 0);
    BOOST_CHECK(pointsOut.begin()->y() == 0);

    BOOST_CHECK(pointsOut.rbegin()->x() == 9);
    BOOST_CHECK(pointsOut.rbegin()->y() == 9);
}

BOOST_AUTO_TEST_CASE( trajectory )
{
    base::Trajectory tr;

    tr.speed = 5;
    BOOST_CHECK(tr.driveForward());

    tr.speed = -5;
    BOOST_CHECK(!tr.driveForward());
}

BOOST_AUTO_TEST_CASE( pressure )
{
    base::Pressure pressure;
    base::samples::Pressure pressureSample;
}

#endif
