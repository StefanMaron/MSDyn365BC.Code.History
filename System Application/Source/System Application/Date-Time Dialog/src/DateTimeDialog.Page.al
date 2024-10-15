﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Dialog for entering DataTime values.
/// </summary>
page 684 "Date-Time Dialog"
{
    Extensible = false;
    PageType = StandardDialog;
    ContextSensitiveHelpPage = 'ui-enter-date-ranges';

    layout
    {
        area(content)
        {
            field(Date; DateValue)
            {
                ApplicationArea = All;
                Caption = 'Date';

                trigger OnValidate()
                begin
                    if TimeValue = 0T then
                        TimeValue := 000000T;
                end;
            }
            field(Time; TimeValue)
            {
                ApplicationArea = All;
                Caption = 'Time';
            }
        }
    }

    actions
    {
    }

    var
        DateValue: Date;
        TimeValue: Time;

    /// <summary>
    /// Setter method to initialize the Date and Time fields on the page.
    /// </summary>
    /// <param name="DateTime">The value to set.</param>
    procedure SetDateTime(DateTime: DateTime)
    begin
        DateValue := DT2Date(DateTime);
        TimeValue := DT2Time(DateTime);
    end;

    /// <summary>
    /// Getter method for the entered datatime value.
    /// </summary>
    /// <returns>The value that is set on the page.</returns>
    procedure GetDateTime(): DateTime
    begin
        exit(CreateDateTime(DateValue, TimeValue));
    end;
}

