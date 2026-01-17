import { Float, PerspectiveCamera, ContactShadows, Stars, Environment, useGLTF, Center, OrbitControls } from '@react-three/drei';
import modelPath from '../../assets/low_poly_university_building_3d_model.glb?url';

export const CampusModel = () => {
    const { scene } = useGLTF(modelPath);

    return (
        <>
            <PerspectiveCamera makeDefault position={[12, 9, 15]} fov={30} />
            <OrbitControls
                enableZoom={false}
                enablePan={false}
                minPolarAngle={Math.PI / 3}
                maxPolarAngle={Math.PI / 2.2}
                autoRotate
                autoRotateSpeed={0.8}
            />

            {/* Optimized Lighting for Low Poly */}
            <ambientLight intensity={1.5} />
            <directionalLight
                position={[5, 10, 5]}
                intensity={2}
                castShadow
            />

            {/* Model with Float Animation */}
            <Float
                position={[0, 1.10, 0]}
                speed={2}
                rotationIntensity={0.1}
                floatIntensity={0.2}
                floatingRange={[-0.1, 0.1]}
            >
                <Center>
                    <primitive
                        object={scene}
                        scale={0.5}
                        rotation={[0, -Math.PI / 4, 0]}
                        dispose={null}
                    />
                </Center>
            </Float>

            {/* Environment & Background */}
            <Environment preset="city" />
            <Stars radius={100} depth={50} count={5000} factor={4} saturation={0} fade speed={1} />
            <ContactShadows opacity={0.6} scale={20} blur={2.5} far={4} color="#0c0a24" />
        </>
    );
};

// Preload the model
useGLTF.preload(modelPath);
