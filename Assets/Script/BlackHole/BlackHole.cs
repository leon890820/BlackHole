using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class BlackHole : MonoBehaviour{
    public Shader shader;
    public Cubemap skyBoxCube;
    public Transform blackHoleTransform;

    public float stepSize;
    public int maxSteps;
    public float h2;
    public Vector2 innerAndOuterRadius;
    public float density;
    public float thickness;
    public Vector3 noiseScale;
    public float depth;

    public NoiseGenerator noiseGenerator;

    Material material;
    public Texture2D noiseTexture;

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (material == null) { 
            material = new Material(shader);
        }
        var pos = blackHoleTransform.position;
        var scale = blackHoleTransform.localScale;


        material.SetTexture("_SkyboxCube", skyBoxCube);        
        material.SetVector("blackholePosition", new Vector4(pos.x, pos.y, pos.z, scale.x));
        material.SetFloat("stepSize", stepSize);
        material.SetInt("maxSteps", maxSteps);
        material.SetFloat("_H2", h2);
        material.SetFloat("innerRadius", innerAndOuterRadius.x);
        material.SetFloat("outerRadius", innerAndOuterRadius.y);
        material.SetFloat("density", density);
        material.SetFloat("thickness", thickness);
        material.SetTexture("NoiseTex", noiseTexture);
        material.SetVector("noiseScale", noiseScale);
        material.SetFloat("u_time", Time.time);
        material.SetFloat("depth", depth);

        Graphics.Blit(source, destination, material);
    }
}
