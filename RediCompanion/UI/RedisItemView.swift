//
//  RedisItemView.swift
//  RediCompanion
//
//  Created by Inder Dhir on 1/3/21.
//

import SwiftUI

struct RedisItemView: View {
    let item: RedisItem

    var body: some View {
        HStack {
            Text(item.type.rawValue.uppercased())
                .bold()
                .foregroundColor(item.type.color)
                .frame(minWidth: 60, alignment: .leading)

            Text(item.name)
                .font(.title3)
                .foregroundColor(.primary)
                .frame(maxWidth: 150, alignment: .leading)
                .truncationMode(.tail)

            Spacer()

            Text(item.value)
                .font(.body)
                .frame(alignment: .trailing)
                .foregroundColor(.gray)
        }
        .padding(2)
    }
}

struct RedisItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RedisItemView(item: RedisItem(type: .string, name: "user2",
                                          value:
                                            """
                                                {
                                                    "glossary": {
                                                        "title": "example glossary",
                                                        "GlossDiv": {
                                                            "title": "S",
                                                            "GlossList": {
                                                                "GlossEntry": {
                                                                    "ID": "SGML",
                                                                    "SortAs": "SGML",
                                                                    "GlossTerm": "Standard Generalized Markup Language",
                                                                    "Acronym": "SGML",
                                                                    "Abbrev": "ISO 8879:1986",
                                                                    "GlossDef": {
                                                                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
                                                                        "GlossSeeAlso": ["GML", "XML"]
                                                                    },
                                                                    "GlossSee": "markup"
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            """
                                          )
            )
        }
//        .colorScheme(.dark)
    }
}
