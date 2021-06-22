page 5447 "Automation Extension Upload"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    Caption = 'extensionUpload', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'extensionUpload';
    EntitySetName = 'extensionUpload';
    ODataKeyFields = ID;
    PageType = API;
    SourceTable = "API Extension Upload"; // table with a BLOB field
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(content; Content)
                {
                    ApplicationArea = All;
                    Caption = 'content', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not loaded then begin
            Insert(true);
            loaded := true;
        end;
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(AutomationAPIManagement);
    end;

    trigger OnModifyRecord(): Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
        FileStream: InStream;
    begin
        if Content.HasValue then begin
            Content.CreateInStream(FileStream);
            ExtensionManagement.UploadExtension(FileStream, GlobalLanguage);
        end;
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
        DotNetALPackageDeploymentSchedule: DotNet ALPackageDeploymentSchedule;
        loaded: Boolean;
}

