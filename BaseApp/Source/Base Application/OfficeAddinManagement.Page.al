page 1610 "Office Add-in Management"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Office Add-in Management';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Office Add-in";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Outlook, O365, Add-in, AddIn, Exchange, Manifest';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Application ID"; "Application ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the application that is being added. ';
                    Visible = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field(Version; Version)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the version of the record';
                }
                field("Manifest Codeunit"; "Manifest Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit where the Office add-in is defined for deployment.';
                }
                field("Deployment Date"; "Deployment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date that add-in was deployed to Office applications. Users will not be able to the add-in until it is deployed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Upload Default Add-in Manifest")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload Default Add-in Manifest', Comment = 'Action - Uploads a default XML manifest definition';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Import an XML manifest file to the add-in. The manifest determines how an add-in is activated in Office applications where it is deployed.';

                trigger OnAction()
                begin
                    UploadManifest;
                end;
            }
            action("Download Add-in Manifest")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Add-in Manifest', Comment = 'Action - downloads the XML manifest document for the add-in';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Export the add-in''s manifest to an XML file. You can then modify the manifest and upload it again.';

                trigger OnAction()
                begin
                    CheckManifest(Rec);
                    AddinManifestManagement.DownloadManifestToClient(Rec, StrSubstNo('%1.xml', Name));
                end;
            }
            action("Deploy Add-in")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deploy Add-in', Comment = 'Action - deploys the XML manifest document for the add-in to an O365 account or tenant';
                Image = UpdateXML;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Deploy the add-in to the Office application so that it can be enabled and used by end users.';

                trigger OnAction()
                var
                    ProgressWindow: Dialog;
                begin
                    ProgressWindow.Open(ProgressDialogTemplateMsg);
                    ProgressWindow.Update(1, ConnectingMsg);
                    ProgressWindow.Update(2, 3000);

                    AddinDeploymentHelper.InitializeAndValidate;

                    ProgressWindow.Update(1, StrSubstNo(DeployingMsg, Name));
                    ProgressWindow.Update(2, 6000);

                    DeployManifest(Rec);
                    Message(AppInstalledMsg);

                    ProgressWindow.Close;
                end;
            }
            action("Deploy All Add-ins")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deploy All Add-ins', Comment = 'Action - deploys the XML manifest document for all add-ins to an O365 account or tenant';
                Image = UpdateXML;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Deploy all the add-in to Office application so that they can be enabled and used by end users.';

                trigger OnAction()
                var
                    OfficeAddin: Record "Office Add-in";
                    ProgressWindow: Dialog;
                begin
                    ProgressWindow.Open(ProgressDialogTemplateMsg);
                    ProgressWindow.Update(1, ConnectingMsg);
                    ProgressWindow.Update(2, 3000);

                    AddinDeploymentHelper.InitializeAndValidate;

                    if OfficeAddin.GetAddins then
                        repeat
                            ProgressWindow.Update(1, StrSubstNo(DeployingMsg, Name));
                            ProgressWindow.Update(2, 6000);
                            DeployManifest(OfficeAddin);
                        until OfficeAddin.Next = 0;
                    Message(AppsInstalledMsg);

                    ProgressWindow.Close;
                end;
            }
            action("Remove Add-in")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Remove Add-in', Comment = 'Action - to remove an add-in from O365/Exchange';
                Image = DeleteXML;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Remove a deployed add-in from the Office application.';

                trigger OnAction()
                begin
                    AddinDeploymentHelper.RemoveApp(Rec);
                    Clear("Deployment Date");
                    CurrPage.Update(true);
                    Message(AppRemovedMsg);
                end;
            }
            action("Reset Default Add-ins")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset Default Add-ins';
                Image = Restore;
                ToolTip = 'Reset the original add-ins to their default state.';

                trigger OnAction()
                begin
                    if Confirm(ResetWarningQst) then
                        AddinManifestManagement.CreateDefaultAddins(Rec);
                end;
            }
        }
    }

    trigger OnInit()
    var
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        if IsEmpty then
            AddinManifestManagement.CreateDefaultAddins(Rec);
    end;

    var
        UploadManifestTxt: Label 'Upload default manifest';
        AddinDeploymentHelper: Codeunit "Add-in Deployment Helper";
        MissingManifestErr: Label 'Cannot find a default manifest for add-in %1. To upload an XML file with the manifest, choose Upload Default Add-in Manifest.', Comment = '%1=The name of an office add-in.';
        OverwriteManifestQst: Label 'The uploaded manifest matches the existing item with name %1, would you like to overwrite it with the values from the uploaded manifest?', Comment = '%1: An Office Add-in name.';
        AppInstalledMsg: Label 'The application deployed correctly to Exchange.';
        AppsInstalledMsg: Label 'The applications deployed correctly to Exchange.';
        AppRemovedMsg: Label 'The application was removed from Exchange.';
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        ProgressDialogTemplateMsg: Label '#1##########\@2@@@@@@@@@@', Locked = true;
        ConnectingMsg: Label 'Connecting to Exchange.', Comment = 'Exchange in this context is the Exchange email service.';
        DeployingMsg: Label 'Deploying %1.', Comment = '%1 is the name of an Office Add-In.';
        ResetWarningQst: Label 'This will restore the original add-in manifest for each of the default add-ins. Are you sure you want to continue?';

    local procedure CheckManifest(var OfficeAddin: Record "Office Add-in")
    begin
        if not OfficeAddin."Default Manifest".HasValue and (OfficeAddin."Manifest Codeunit" = 0) then
            Error(MissingManifestErr, OfficeAddin.Name);
    end;

    local procedure UploadManifest()
    var
        OfficeAddin: Record "Office Add-in";
        TempOfficeAddin: Record "Office Add-in" temporary;
        FileManagement: Codeunit "File Management";
        ManifestLocation: Text;
    begin
        // Insert into a temp record so we can do some comparisons
        TempOfficeAddin.Init();
        TempOfficeAddin.Insert();

        ManifestLocation := FileManagement.UploadFile(UploadManifestTxt, '*.xml');

        // If the selected record is new, use that one - otherwise create a new one
        AddinManifestManagement.UploadDefaultManifest(TempOfficeAddin, ManifestLocation);

        // If the uploaded item already exists, overwrite, otherwise insert a new one.
        if not OfficeAddin.Get(TempOfficeAddin."Application ID") then begin
            OfficeAddin.Copy(TempOfficeAddin);
            OfficeAddin.Insert();
        end else
            if DIALOG.Confirm(OverwriteManifestQst, true, OfficeAddin.Name) then begin
                // Persist codeunit and company values when overwriting
                TempOfficeAddin."Manifest Codeunit" := OfficeAddin."Manifest Codeunit";
                OfficeAddin.Copy(TempOfficeAddin);
                OfficeAddin.Modify();
            end;
    end;

    local procedure DeployManifest(var OfficeAddIn: Record "Office Add-in")
    begin
        CheckManifest(OfficeAddIn);

        AddinDeploymentHelper.DeployManifest(OfficeAddIn);
        CurrPage.Update(true);
    end;
}

