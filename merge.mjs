import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
import fs from 'fs';

async function mergeAnimations() {
    const io = new NodeIO()
        .registerExtensions(ALL_EXTENSIONS)
        .registerDependencies({
            'draco3d.decoder': await draco3d.createDecoderModule(),
            'draco3d.encoder': await draco3d.createEncoderModule(),
        });

    const avatarDoc = await io.read('assets/models/64f1a714fe61576b46f27ca2.glb');
    const animDoc = await io.read('assets/models/animations.glb');

    // Map nodes in the target file
    const avatarNodes = new Map();
    for (const node of avatarDoc.getRoot().listNodes()) {
        if (node.getName()) {
            avatarNodes.set(node.getName(), node);
        }
    }

    const root = avatarDoc.getRoot();
    let buffer = root.listBuffers()[0];
    if (!buffer) {
        buffer = avatarDoc.createBuffer();
    }

    // Clear any existing animations in avatarDoc
    for (const anim of root.listAnimations()) {
        anim.dispose();
    }

    let mergedCount = 0;
    for (const anim of animDoc.getRoot().listAnimations()) {
        const newAnim = avatarDoc.createAnimation().setName(anim.getName() || `Animation_${mergedCount}`);

        for (const channel of anim.listChannels()) {
            const sourceNode = channel.getTargetNode();
            if (!sourceNode) continue;

            const targetNode = avatarNodes.get(sourceNode.getName());
            if (!targetNode) continue; // Skip if avatar doesn't have this bone

            const sampler = channel.getSampler();

            const sourceInput = sampler.getInput();
            const inputAcc = avatarDoc.createAccessor()
                .setBuffer(buffer)
                .setType(sourceInput.getType())
                .setArray(sourceInput.getArray());

            const sourceOutput = sampler.getOutput();
            const outputAcc = avatarDoc.createAccessor()
                .setBuffer(buffer)
                .setType(sourceOutput.getType())
                .setArray(sourceOutput.getArray());

            const newSampler = avatarDoc.createAnimationSampler()
                .setInterpolation(sampler.getInterpolation())
                .setInput(inputAcc)
                .setOutput(outputAcc);

            const newChannel = avatarDoc.createAnimationChannel()
                .setTargetNode(targetNode)
                .setTargetPath(channel.getTargetPath())
                .setSampler(newSampler);

            newAnim.addChannel(newChannel);
        }
        mergedCount++;
    }

    console.log(`Merged ${mergedCount} animations into avatar.`);
    await io.write('assets/models/avatar_animated.glb', avatarDoc);
}

mergeAnimations().catch(err => {
    console.error("ERROR:", err);
    process.exit(1);
});
