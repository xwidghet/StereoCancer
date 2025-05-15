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

		scFoldout.font = (Font)Resources.Load("Oswald-VariableFont_wght", typeof(Font));
		scFoldout.fontSize = 14;

        return scFoldout;
    }
}
