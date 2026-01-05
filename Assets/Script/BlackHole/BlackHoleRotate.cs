using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlackHoleRotate : MonoBehaviour
{
    public float rotateSpeed = 0.5f;
    // Update is called once per frame
    void Update()
    {
        var euler = transform.eulerAngles;
        euler.y += rotateSpeed * Time.deltaTime;
        transform.rotation = Quaternion.Euler(euler);
    }
}
