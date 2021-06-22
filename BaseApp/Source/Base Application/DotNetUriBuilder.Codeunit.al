codeunit 3028 DotNet_UriBuilder
{

    trigger OnRun()
    begin
    end;

    var
        DotNetUriBuilder: DotNet UriBuilder;

    procedure Init(Url: Text)
    begin
        DotNetUriBuilder := DotNetUriBuilder.UriBuilder(Url);
    end;

    procedure SetQuery(Text: Text)
    begin
        DotNetUriBuilder.Query := Text;
    end;

    procedure GetQuery(): Text
    begin
        exit(DotNetUriBuilder.Query);
    end;

    /// <summary>
    /// This procedure is a wrapper for the DotNet getter function for the UriBuilder.Uri property.
    /// </summary>
    /// <param name=DotNet_Uri>The combined Uri that has been built in the builder (wrapped in an instance of the DotNet_Uri codeunit)</param>
    procedure GetUri(var DotNet_Uri: Codeunit DotNet_Uri)
    begin
        DotNet_Uri.SetUri(DotNetUriBuilder.Uri);
    end;

}
