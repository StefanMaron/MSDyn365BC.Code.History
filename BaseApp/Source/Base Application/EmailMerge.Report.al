report 5084 "Email Merge"
{
    DefaultLayout = RDLC;
    RDLCLayout = './EmailMerge.rdlc';
    Caption = 'Email Merge';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(Company_Information_Picture; CompanyInformation.Picture)
            {
            }
            column(Company_Information_Name; CompanyInformation.Name)
            {
            }
            column(Company_Information_Address; CompanyInformation.Address)
            {
            }
            column(Company_Information_Address_2; CompanyInformation."Address 2")
            {
            }
            column(Company_Information_Post_Code; CompanyInformation."Post Code")
            {
            }
            column(Company_Information_City; CompanyInformation.City)
            {
            }
            column(SalespersonPurchaser_Name; SalespersonPurchaser.Name)
            {
            }
            column(SalespersonPurchaser_Job_Title; SalespersonPurchaser."Job Title")
            {
            }
            column(Content; Content)
            {
            }
            column(Contact_Mail_Address; Contact_Mail_Address)
            {
            }
            column(Formal_Salutation; Formal_Salutation)
            {
            }
            column(Informal_Salutation; Informal_Salutation)
            {
            }
            column(Document_Date; Document_Date)
            {
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        SegmentLine: Record "Segment Line";
        CompanyInformation: Record "Company Information";
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Content: Text;
        Contact_Mail_Address: Text;
        Formal_Salutation: Text;
        Informal_Salutation: Text;
        Document_Date: Text;

    procedure InitializeRequest(InSegmentLine: Record "Segment Line"; InContent: Text)
    begin
        SegmentLine := InSegmentLine;
        Content := InContent;

        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);

        if Contact.Get(SegmentLine."Contact No.") then begin
            Formal_Salutation := Contact.GetSalutation(0, SegmentLine."Language Code");
            Informal_Salutation := Contact.GetSalutation(1, SegmentLine."Language Code");
        end;

        if SalespersonPurchaser.Get(InSegmentLine."Salesperson Code") then;

        Contact_Mail_Address := '';
        Document_Date := Format(SegmentLine.Date, 0, 4);
    end;
}

