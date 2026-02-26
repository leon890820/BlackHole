using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ContainerVis : MonoBehaviour {

    public Color colour = Color.green;
    public bool displayOutline = true;

    void OnDrawGizmosSelected() {
        if (!displayOutline) return;

        Gizmos.color = colour;
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
        Gizmos.matrix = Matrix4x4.identity;
    }
}