//
//  BaringWidgetBundle.swift
//  BaringWidget
//
//  Created by 김지홍 on 1/28/26.
//

import WidgetKit
import SwiftUI

@main
struct BaringWidgetBundle: WidgetBundle {
    var body: some Widget {
        BaringWidget()
        TodoWidget()
        BaringWidgetControl()
        BaringWidgetLiveActivity()
    }
}
