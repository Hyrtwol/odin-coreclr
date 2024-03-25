using System;
using System.Runtime.InteropServices;

public delegate bool UnmanagedCallbackDelegate(string funcName, string jsonArgs);

public static unsafe class Gateway
{
    public static string Bootstrap() => typeof(Gateway).Assembly.Location;

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

    public static double Sum2(double* x, int n)
    {
        var span = new Span<double>(x, n);
        return span.ToArray().Sum();
    }

	[return: MarshalAs(UnmanagedType.LPStr)]
	public static string ManagedDirectMethod(
		[MarshalAs(UnmanagedType.LPStr)] string funcName,
		[MarshalAs(UnmanagedType.LPStr)] string jsonArgs,
		UnmanagedCallbackDelegate unmanagedCallback)
	{
		Console.WriteLine($"C#>> {funcName}, {jsonArgs}");

		string strRet = null;

		try
		{
			var res = unmanagedCallback?.Invoke(funcName, jsonArgs);
			strRet = $"Invoke was \"{res}\"";
		}
		catch (Exception e)
		{
			strRet = $"ERROR in \"{funcName}\" invoke:{Environment.NewLine} {e}";
		}

		return strRet;
	}
}
