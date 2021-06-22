page 9623 "Finish Up Design"
{
    Caption = 'Finish Up Design';
    PageType = NavigatePage;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                Visible = SaveVisible;
                field(AppName; AppName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    Editable = NameAndPublisherEnabled;
                    Enabled = NameAndPublisherEnabled;
                    NotBlank = true;
                }
                field(Publisher; Publisher)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Publisher';
                    Editable = NameAndPublisherEnabled;
                    Enabled = NameAndPublisherEnabled;
                    NotBlank = true;
                }
                field(DownloadCode; DownloadCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Code';
                    Enabled = DownloadCodeEnabled;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Save)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Save';
                Image = Approve;
                InFooterBar = true;
                Visible = SaveVisible;

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    NvOutStream: OutStream;
                    Designer: DotNet NavDesignerALFunctions;
                    FileName: Text;
                    CleanFileName: Text;
                begin
                    if StrLen(AppName) = 0 then
                        Error(BlankNameErr);

                    if StrLen(Publisher) = 0 then
                        Error(BlankPublisherErr);

                    if not Designer.ExtensionNameAndPublisherIsValid(AppName, Publisher) then
                        Error(DuplicateNameAndPublisherErr);

                    SaveVisible := false;

                    Designer.SaveDesignerExtension(AppName, Publisher);

                    if DownloadCode and DownloadCodeEnabled then begin
                        TempBlob.CreateOutStream(NvOutStream);
                        Designer.GenerateDesignerPackageZipStream(NvOutStream, Publisher, AppName);
                        FileName := StrSubstNo(ExtensionFileNameTxt, AppName, Publisher);
                        CleanFileName := Designer.SanitizeDesignerFileName(FileName, '_');
                        FileManagement.BLOBExport(TempBlob, CleanFileName, true);
                    end;

                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnInit()
    var
        Designer: DotNet NavDesignerALFunctions;
    begin
        SaveVisible := true;
        DownloadCode := false;
        AppName := Designer.GetDesignerExtensionName;
        Publisher := Designer.GetDesignerExtensionPublisher;
        DownloadCodeEnabled := Designer.GetDesignerExtensionShowMyCode;
        if AppName = '' then
            NameAndPublisherEnabled := true
        else
            NameAndPublisherEnabled := false;
    end;

    var
        SaveVisible: Boolean;
        ExtensionFileNameTxt: Label '%1_%2_1.0.0.0.zip', Comment = '%1=Name, %2=Publisher', Locked = true;
        AppName: Text[250];
        Publisher: Text[250];
        DownloadCode: Boolean;
        BlankNameErr: Label 'Name cannot be blank.', Comment = 'Specifies that field cannot be blank.';
        BlankPublisherErr: Label 'Publisher cannot be blank.', Comment = 'Specifies that field cannot be blank.';
        NameAndPublisherEnabled: Boolean;
        DownloadCodeEnabled: Boolean;
        DuplicateNameAndPublisherErr: Label 'The specified name and publisher are already used in another extension. Please specify another name or publisher.', Comment = 'An extension with the same name and publisher already exists.';
}

