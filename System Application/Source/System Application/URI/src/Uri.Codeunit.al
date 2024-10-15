// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides an object representation of a uniform resource identifier (URI) and easy access to the parts of the URI.
/// </summary>
/// <remarks>Visit https://docs.microsoft.com/en-us/dotnet/api/system.uri for more information.</remarks>
codeunit 3060 Uri
{
    Access = Public;

    /// <summary>
    /// Initializes a new instance of the Uri class with the specified URI.
    /// </summary>
    /// <remarks>Visit https://docs.microsoft.com/en-us/dotnet/api/system.uri.-ctor#System_Uri__ctor_System_String_ for more information.</remarks>
    /// <param name="UriString">A string that identifies the resource to be represented by the Uri instance. Note that an IPv6 address in string form must be enclosed within brackets. For example, "http://[2607:f8b0:400d:c06::69]".</param>
    procedure Init(UriString: Text)
    begin
        Uri := Uri.Uri(UriString);
    end;

    /// <summary>
    /// Gets the absolute URI.
    /// </summary>
    /// <returns>A string containing the entire URI.</returns>
    procedure GetAbsoluteUri(): Text
    begin
        exit(Uri.AbsoluteUri)
    end;

    /// <summary>
    /// Gets the scheme name for the URI.
    /// </summary>
    /// <remarks>Visit https://docs.microsoft.com/en-us/dotnet/api/system.uri.scheme for more information.</remarks>
    /// <returns>A text that contains the scheme for this URI, converted to lowercase.</returns>
    procedure GetScheme(): Text
    begin
        exit(Uri.Scheme);
    end;

    /// <summary>
    /// Gets a list containing the path segments that make up the specified URI.
    /// </summary>
    /// <remarks>Visit https://docs.microsoft.com/en-us/dotnet/api/system.uri.segments for more information.</remarks>
    /// <param name="Segments">An out variable that contains the path segments that make up the specified URI.</param>
    procedure GetSegments(var Segments: List of [Text])
    var
        Result: List of [Text];
        Segment: DotNet String;
    begin
        foreach Segment in Uri.Segments do
            Result.Add(Segment);

        Segments := Result;
    end;

    /// <summary>
    /// Converts a string to its escaped representation.
    /// </summary>
    /// <remarks>Visit https://docs.microsoft.com/en-us/dotnet/api/system.uri.escapedatastring for more information.</remarks>
    /// <param name="TextToEscape"></param>
    /// <returns>A string that contains the escaped representation of <paramref name="TextToEscape:"/>.</returns>
    procedure EscapeDataString(TextToEscape: Text): Text
    begin
        exit(Uri.EscapeDataString(TextToEscape));
    end;

    /// <summary>
    /// Converts a string to its unescaped representation.
    /// </summary>
    /// <remarks>Visit https://docs.microsoft.com/en-us/dotnet/api/system.uri.unescapedatastring for more information.</remarks>
    /// <param name="TextToUnescape"></param>
    /// <returns>A string that contains the unescaped representation of <paramref name="TextToUnescape:"/>.</returns>
    procedure UnescapeDataString(TextToUnescape: Text): Text
    begin
        exit(Uri.UnescapeDataString(TextToUnescape));
    end;

    /// <summary>
    /// Gets the underlying .Net Uri variable.
    /// </summary>
    /// <param name="OutUri">A .Net object of class Uri that holds the underlying .Net Uri variable.</param>
    [Scope('OnPrem')]
    procedure GetUri(var OutUri: DotNet Uri)
    begin
        OutUri := Uri;
    end;

    /// <summary>
    /// Sets the underlying .Net Uri variable.
    /// </summary>
    /// <param name="NewUri">A .Net object of class Uri to set to the underlying .Net Uri variable.</param>
    [Scope('OnPrem')]
    procedure SetUri(NewUri: DotNet Uri)
    begin
        Uri := NewUri;
    end;

    var
        Uri: DotNet Uri;
}