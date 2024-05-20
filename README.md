# Platform Maternal, Newborn, and Child Health (MNCH)
This repo holds a collection of flows. The purpose of these flows is to act as base/building blocks, to be able to create MNCH services. They're designed to be reusable across multiple services.

## Architecture
The flows use [ContentRepo](https://github.com/praekeltfoundation/contentrepo/) to store and manage the content of the flows.

The flows are exports of [Turn Stacks](https://whatsapp.turn.io/docs/build/stacks_overview), which can also be represented as [Flow Interop](https://flowinterop.org/) flow definitions. The idea is to import them into a new service, configure them, and then use them to run that specific MNCH intervention.

```mermaid
flowchart LR
    WA[WhatsApp] <--> T[Turn]
    T <--> CR[ContentRepo]
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
