page 9820 "Control Add-ins"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Control Add-ins';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Control Add-in Resource';
    SourceTable = "Add-in";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Add-in Name"; "Add-in Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Client Control Add-in that is registered on the Business Central Server.';
                }
                field("Public Key Token"; "Public Key Token")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the public key token that is associated with the Add-in.';

                    trigger OnValidate()
                    begin
                        "Public Key Token" := DelChr("Public Key Token", '<>', ' ');
                    end;
                }
                field(Version; Version)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the Client Control Add-in that is registered on a Business Central Server.';
                }
                field(Category; Category)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the add-in. The following table describes the types that are available:';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the Client Control Add-in.';
                }
                field("Resource.HASVALUE"; Resource.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource', Locked = true;
                    ToolTip = 'Specifies the URL to the resource zip file.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Control Add-in Resource")
            {
                Caption = 'Control Add-in Resource';
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Import a control add-in definition from a file.';

                    trigger OnAction()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                        RecordRef: RecordRef;
                        ResourceName: Text;
                    begin
                        if Resource.HasValue then
                            if not Confirm(ImportQst) then
                                exit;

                        ResourceName := FileManagement.BLOBImportWithFilter(
                            TempBlob, ImportTitleTxt, '',
                            ImportFileTxt + ' (*.zip)|*.zip|' + AllFilesTxt + ' (*.*)|*.*', '*.*');

                        if ResourceName <> '' then begin
                            RecordRef.GetTable(Rec);
                            TempBlob.ToRecordRef(RecordRef, FieldNo(Resource));
                            RecordRef.SetTable(Rec);
                            CurrPage.SaveRecord;

                            Message(ImportDoneMsg);
                        end;
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Export a control add-in definition to a file.';

                    trigger OnAction()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                    begin
                        TempBlob.FromRecord(Rec, FieldNo(Resource));
                        if TempBlob.HasValue then
                            FileManagement.BLOBExport(TempBlob, "Add-in Name" + '.zip', true)
                        else
                            Message(NoResourceMsg);
                    end;
                }
                action(Clear)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear';
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Clear the resource from the selected control add-in.';

                    trigger OnAction()
                    begin
                        if not Resource.HasValue then
                            exit;

                        Clear(Resource);
                        CurrPage.SaveRecord;

                        Message(RemoveDoneMsg);
                    end;
                }
            }
        }
    }

    var
        AllFilesTxt: Label 'All Files';
        ImportFileTxt: Label 'Control Add-in Resource';
        ImportDoneMsg: Label 'The control add-in resource has been imported.';
        ImportQst: Label 'The control add-in resource is already specified.\Do you want to overwrite it?';
        ImportTitleTxt: Label 'Import Control Add-in Resource';
        NoResourceMsg: Label 'There is no resource for the control add-in.';
        RemoveDoneMsg: Label 'The control add-in resource has been removed.';
}

