page 31131 "Certificates CZ"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Certificates';
    DelayedInsert = true;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Encryption';
    SourceTable = "Certificate CZ";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Certificate Code"; "Certificate Code")
                {
                    ToolTip = 'Specifies the code for the general identification of the certificate.';
                }
                field("Store Type"; "Store Type")
                {
                    ToolTip = 'Specifies the type of certificate store.';
                }
                field("Store Location"; "Store Location")
                {
                    ToolTip = 'Specifies the location of the windows certificate store for the client or server store type.';
                }
                field("Store Name"; "Store Name")
                {
                    ToolTip = 'Specifies the name of the location in the windows certificate store for the client or server store type.';
                }
                field(Thumbprint; Thumbprint)
                {
                    ShowMandatory = "Store Type" <> "Store Type"::Database;
                    ToolTip = 'Specifies the thumbprint of the certificate.';
                }
                field("Valid From"; "Valid From")
                {
                    ToolTip = 'Specifies the date from which the certificate is valid.';
                }
                field("Valid To"; "Valid To")
                {
                    ToolTip = 'Specifies the date to which the certificate is valid.';
                }
                field(Description; Description)
                {
                    ToolTip = 'Specifies the description of the certificate';
                }
                field(HasCertificate; HasCertificate)
                {
                    Caption = 'Imported Certificate';
                    ToolTip = 'Specifies whether the certificate is imported to database.';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ToolTip = 'Specifies the ID of the user associated with the certificate.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Show certificate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show certificate';
                    Image = Certificate;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Show imported certificate.';

                    trigger OnAction()
                    begin
                        Show;
                    end;
                }
                action("Import certificate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import certificate';
                    Ellipsis = true;
                    Enabled = "Store Type" = "Store Type"::Database;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import an certificate';

                    trigger OnAction()
                    begin
                        ImportCertificate;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(navigation)
        {
            action(EncryptionManagement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetFilter("User ID", '%1|%2', '', UserId);
        FilterGroup(0);
    end;
}

