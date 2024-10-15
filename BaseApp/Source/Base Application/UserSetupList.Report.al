#if not CLEAN18
report 11796 "User Setup List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './UserSetupList.rdlc';
    Caption = 'User Setup List (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("User Setup"; "User Setup")
        {
            RequestFilterFields = "User ID";
            column(ginPageGroup; PageGroup)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(User_Setup__Check_Journal_Templates_; Format("Check Journal Templates"))
            {
            }
            column(User_Setup__Check_Dimension_Values_; Format("Check Dimension Values"))
            {
            }
            column(User_Setup__Check_Bank_Accounts_; Format("Check Bank Accounts"))
            {
            }
            column(User_Setup__Check_Location_Code_; Format("Check Location Code"))
            {
            }
            column(User_Setup__Check_Posting_Date__sys__date__; Format("Check Posting Date (sys. date)"))
            {
            }
            column(User_Setup__Check_Posting_Date__work_date__; Format("Check Posting Date (work date)"))
            {
            }
            column(User_Setup__Check_Document_Date_sys__date__; Format("Check Document Date(sys. date)"))
            {
            }
            column(User_Setup__Check_Document_Date_work_date__; Format("Check Document Date(work date)"))
            {
            }
            column(User_Setup__User_Name_; "User Name")
            {
            }
            column(User_Setup__User_ID_; "User ID")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(User_Checks_ListCaption; User_Checks_ListCaptionLbl)
            {
            }
            column(User_Setup__Check_Journal_Templates_Caption; FieldCaption("Check Journal Templates"))
            {
            }
            column(User_Setup__Check_Dimension_Values_Caption; FieldCaption("Check Dimension Values"))
            {
            }
            column(User_Setup__Check_Bank_Accounts_Caption; FieldCaption("Check Bank Accounts"))
            {
            }
            column(User_Setup__Check_Location_Code_Caption; FieldCaption("Check Location Code"))
            {
            }
            column(User_Setup__Check_Posting_Date__sys__date__Caption; FieldCaption("Check Posting Date (sys. date)"))
            {
            }
            column(User_Setup__Check_Posting_Date__work_date__Caption; FieldCaption("Check Posting Date (work date)"))
            {
            }
            column(User_Setup__Check_Document_Date_sys__date__Caption; FieldCaption("Check Document Date(sys. date)"))
            {
            }
            column(User_Setup__Check_Document_Date_work_date__Caption; FieldCaption("Check Document Date(work date)"))
            {
            }
            column(User_Setup__User_Name_Caption; FieldCaption("User Name"))
            {
            }
            column(User_Setup__User_ID_Caption; FieldCaption("User ID"))
            {
            }
            column(gboNewPagePerRec; NewPagePerRec)
            {
            }
            dataitem("User Setup Line"; "User Setup Line")
            {
                DataItemLink = "User ID" = FIELD("User ID");
                DataItemTableView = SORTING("User ID", Type, "Line No.");
                column(User_Setup_Line__Code___Name_; "Code / Name")
                {
                }
                column(User_Setup_Line_Type; Type)
                {
                }
                column(User_Setup_Line_TypeCaption; FieldCaption(Type))
                {
                }
                column(User_Setup_Line__Code___Name_Caption; FieldCaption("Code / Name"))
                {
                }
                column(User_Setup_Line_User_ID; "User ID")
                {
                }
                column(User_Setup_Line_Line_No_; "Line No.")
                {
                }
                column(User_Setup_Line; 1)
                {
                }
            }
            dataitem("Selected Dimension"; "Selected Dimension")
            {
                DataItemLink = "User ID" = FIELD("User ID");
                DataItemTableView = SORTING("User ID", "Object Type", "Object ID", "Analysis View Code", "Dimension Code");
                column(Selected_Dimension__Dimension_Code_; "Dimension Code")
                {
                }
                column(Selected_Dimension__Dimension_Value_Filter_; "Dimension Value Filter")
                {
                }
                column(Selected_Dimension__Dimension_Code_Caption; FieldCaption("Dimension Code"))
                {
                }
                column(Selected_Dimension__Dimension_Value_Filter_Caption; FieldCaption("Dimension Value Filter"))
                {
                }
                column(Selected_Dimension_User_ID; "User ID")
                {
                }
                column(Selected_Dimension_Object_Type; "Object Type")
                {
                }
                column(Selected_Dimension_Object_ID; "Object ID")
                {
                }
                column(Selected_Dimension_Analysis_View_Code; "Analysis View Code")
                {
                }
                column(Selected_Dimension; 1)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Object Type", 1);
                    SetRange("Object ID", DATABASE::"User Setup");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if NewPagePerRec then
                    PageGroup += 1;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPagePerRec; NewPagePerRec)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'User on new page';
                        ToolTip = 'Specifies if every user will appear in a new page';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        NewPagePerRec: Boolean;
        PageGroup: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        User_Checks_ListCaptionLbl: Label 'User Checks List';
}
#endif
