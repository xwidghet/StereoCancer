using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class StereoCancerCSS : MonoBehaviour
{
    public static GUIStyle createSCFoldOutStyle()
    {
        // Seems kinda uncouth of me to sneak this in here but ¯\_(ツ)_/¯
        EditorGUIUtility.labelWidth = 256;

        GUIStyle scFoldout = new GUIStyle(EditorStyles.foldout);

        // Make the foldout background extend off-screen when open.
        scFoldout.overflow.right = 1000;

        // Enable HTML text styling for if I add big and bold conditional performance warnings later
        scFoldout.richText = true;

        // Cancer Space styling (GPL-3.0 License)
        // https://github.com/AkaiMage/VRC-Cancerspace/blob/5118fc7c40977f73791d39fe3929e90c14eb5f77/Editor/CancerspaceInspector.cs#L98
        scFoldout.fontStyle = FontStyle.Bold;
        scFoldout.onNormal = EditorStyles.boldLabel.onNormal;
        scFoldout.onFocused = EditorStyles.boldLabel.onFocused;

        return scFoldout;
    }
}
