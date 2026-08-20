using System;
using System.Runtime.InteropServices;

public delegate bool UnmanagedCallbackDelegate(string actionName, string jsonArgs);

public struct SizeOf
{
    public int Int, Double, Float, Pointer;
}

public static unsafe class Gateway
{
    public static string AssemblyLocation() => typeof(Gateway).Assembly.Location;

    public static void SizeOfStuff(SizeOf* sof)
    {
        sof->Int = sizeof(int);
        sof->Double = sizeof(double);
        sof->Float = sizeof(float);
        sof->Pointer = sizeof(nint);
    }

    public static double Plus(double x, double y) => x + y;

    public static double Sum(double* x, int n)
    {
        double sum = 0;
        for (var i = 0; i < n; i++)
        {
            sum += x[i];
        }
        return sum;
    }

    [return: MarshalAs(UnmanagedType.LPStr)]
	public static string ManagedDirectMethod(
		[MarshalAs(UnmanagedType.LPStr)] string actionName,
		[MarshalAs(UnmanagedType.LPStr)] string jsonArgs,
		UnmanagedCallbackDelegate unmanagedCallback)
	{
		Console.WriteLine($"C#>> {actionName}, {jsonArgs}");

		string strRet = null;

		try
		{
			var res = unmanagedCallback?.Invoke(actionName, jsonArgs);
			strRet = $"Invoke was \"{res}\"";
		}
		catch (Exception ex)
		{
			strRet = $"ERROR in \"{actionName}\" invoke:{Environment.NewLine} {ex}";
		}

		return strRet;
	}
}
